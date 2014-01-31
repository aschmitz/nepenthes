class Scan < ActiveRecord::Base
  belongs_to :ip_address
  attr_accessible :results, :options
  serialize :options
  has_many :ports
  
  def process!
    return if self.processed
    
    doc = Nokogiri::XML(self.results)
    unless doc.at('host/address/@addr')
      Sidekiq::Client.enqueue(FullScannerWorker, self.id, self.ip_address.to_s)
      return
    end
    
    ip_address = IpAddress.find_by_dotted(doc.at('host/address/@addr').value)
    empty_ports = []
    have_ports = false

    extrainfo = doc.at('//taskend[@task="SYN Stealth Scan"]/@extrainfo').value
    self.timed_out = extrainfo =~ /timed out/
    
    doc.xpath('//port').each do |port|
      if port.at('state/@state').value == 'open'
        portRow = ip_address.ports.find_or_create_by_number(port['portid'])
        portRow.scan = self
        if port.at('service/@product')
          portRow.product = port.at('service/@product').value
          portRow.tag_list << portRow.product
        end
        if port.at('service/@version')
          portRow.version = port.at('service/@version').value
          portRow.tag_list << portRow.version
        end
        if port.at('service/@extrainfo')
          portRow.extra = port.at('service/@extrainfo').value
        end
        portRow.save
      else
        empty_ports << port['portid']
      end
    end
    
    ip_address.ports.where(:number => empty_ports).destroy_all
    self.processed = true
    self.save
  end
  
  def get_host_xml
    return unless self.processed
    
    doc = Nokogiri::XML(self.results)
    doc.xpath('//host')[0]
  end
  
  def self.get_all_scanned_xml
    template = Nokogiri::XML(Scan.where(:processed => true).first.results)
    
    scans = Scan.where(:processed => true)
    template.xpath('//hosts').remove
    hosts = template.xpath('//nmaprun')[0]
    scans.where(:processed => true).find_each do |scan|
      hosts << scan.get_host_xml
    end
    
    template.to_xml
  end
end
