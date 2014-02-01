class IpAddress < ActiveRecord::Base
  belongs_to :region
  belongs_to :tag
  has_many :scans, :dependent => :destroy
  has_many :ports, :dependent => :destroy
  attr_accessible :address, :tags
  acts_as_taggable
  store :settings, coder: JSON
  
  default_scope { order(:address) }

  scope :with_ports, -> { joins(:ports).distinct }
  
  def address_and_hostname
    if self.hostname.nil? || self.hostname.empty?
      self.to_s
    else
      "#{self.to_s} (#{self.hostname})"
    end
  end
  
  def address_or_hostname
    if (self.hostname != nil) and self.hostname.empty?
      self.to_s
    else
      self.hostname
    end
  end
  
  def to_s
    NetAddr::CIDR.create(self.address.to_i).ip
  end
  
  def self.find_by_dotted(dotted)
    self.find_by_address(NetAddr::CIDR.create(dotted).to_i(:ip))
  end
  
  def self.queue_full_scans!
    queued = 0
    scanlater = []
    # We'd like this to really only queue full scans where we haven't before,
    #  but we don't store that information (yet).
    self.where(has_full_scan: false).each do |ip|
      if ip.ports.count > 0
        scan = ip.scans.create
        Sidekiq::Client.enqueue(FullScannerWorker, scan.id, ip.to_s)
        queued += 1
      else
        scanlater << ip
      end
    end
    
    scanlater.each do |ip|
      scan = ip.scans.create
      Sidekiq::Client.enqueue(FullScannerWorker, scan.id, ip.to_s)
      queued += 1
    end
    
    queued
  end

  def self.queue_rescans! timeout
    queued = 0
    self.where(full_scan_timed_out: true).each do |ip|
      scan = ip.scans.create
      ip.full_scan_timed_out = false
      ip.save!
      Sidekiq::Client.enqueue(FullScannerWorker, scan.id, ip.to_s, timeout)
      queued += 1
    end
    # do we want to delete the old scans?
    # or repurpose them?

    queued
  end
  
  def self.queue_quick_scans!
    queued = 0
    self.includes(:scans).where(:scans => {:ip_address_id => nil}).each do |ip|
      ip.queue_scan!
      queued += 1
    end
    
    queued
  end
  
  def queue_scan!(opts = ['-Pn', '-p', '80,443,22,25,21,8080,23,3306,143,53',
      '-sV', '--version-light'])
    # Recommend something like the above.
    unless opts.kind_of?(Array)
      throw 'opts must be an array.'
    end
    
    scan = self.scans.new(:options => opts)
    scan.save!
    Sidekiq::Client.enqueue(ScannerWorker, scan.id, self.to_s, opts)
  end
  
  def self.not_hostname_checked
    self.where(hostname: nil)
  end
  
  def self.queue_hostname_checks!
    queued = 0
    self.not_hostname_checked.each do |ip|
      ip.queue_check_hostname!
      queued += 1
    end
    
    queued
  end
  
  def queue_check_hostname!
    Sidekiq::Client.enqueue(HostnameWorker, self.id, self.to_s)
  end

  def has_port x
    self.ports.where(number: x).any?
  end

  def port_numbers
    self.ports.map(&:number)
  end

  def self.to_csv
    CSV.generate do |csv|
      columns = ['host'] + Port::COMMON_PORTS + ['other']
      csv << columns
      IpAddress.with_ports.each do |addr|
        ports = addr.port_numbers
        commons = Port::COMMON_PORTS.map {|x| 'X' if ports.include? x}
        others = (ports - Port::COMMON_PORTS).join ', '
        row = [addr.address_and_hostname] + commons + [others]
        csv << row
      end
    end
  end
end
