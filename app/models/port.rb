class Port < ActiveRecord::Base
  belongs_to :ip_address, counter_cache: true
  belongs_to :scan
  has_many :screenshots, as: :screenshotable, dependent: :destroy
  attr_accessible :number, :product, :version, :extra, :notes, :done
  acts_as_taggable
  store :settings, coder: JSON
  
  # We try to avoid sending things to these ports (screenshots, SSL handshakes,
  #  etc.) because it may cause problems. For example, printers printing
  #  data of some sort.
  AVOID_PORTS = [9100]
  
  SCREENSHOT_PRIORITY_PORTS = []
  (0..65535).step(1000).each do |base|
    SCREENSHOT_PRIORITY_PORTS.concat [base + 80, base + 443]
  end
  SCREENSHOT_PRIORITY_PORTS.concat [
    8081, 8082,
    3000, 3001, 3002,
  ]

  # used for reporting
  COMMON_PORTS = [21, 25, 53, 80, 443, 1080, 1443]
  
  def queue_http_title_scan!
    Sidekiq::Client.enqueue(HttpTitleWorker, self.id, self.ip_address.to_s, self.number)
  end
  
  def product_str
    if self.product
      if self.version
        "#{self.product} (#{self.version})"
      else
        self.product
      end
    else
      ''
    end
  end
  
  def probably_ssl?
    self.ssl or (self.ssl == nil and self.number % 1000 == 443)
  end
  
  def take_screenshot!(path = '/')
    protocol = 'http'
    if self.probably_ssl?
      protocol = 'https'
    end
    url = "#{protocol}://#{self.ip_address.to_s}:#{self.number}#{path}"
    
    existing = self.screenshots.where(url: url)
    if existing.count > 0
      return existing.first
    end
    
    screenshot = self.screenshots.new(url: url)
    screenshot.save!
    screenshot.take!
    screenshot
  end
  
  def check_ssl!
    Sidekiq::Client.enqueue(SslWorker, self.id, self.ip_address.to_s,
        self.number)
  end

  def check_nikto!
    Sidekiq::Client.enqueue(NiktoWorker, self.id, self.ip_address.to_s,
        self.number, self.probably_ssl?)
  end
  
  def self.not_screenshotted(force_avoided_ports = false)
    return self.where(screenshotted: false) if force_avoided_ports
    self.where(screenshotted: false).where('number NOT IN (?)', AVOID_PORTS)
  end
  
  def self.not_ssl_checked(force_avoided_ports = false)
    return self.where(ssl: nil) if force_avoided_ports
    self.where(ssl: nil).where('number NOT IN (?)', AVOID_PORTS)
  end

  def self.not_nikto_scanned(force_avoided_ports = false)
    return self.where(nikto_results: nil).where(
        'number IN (631,8000,8008,8009,8888) OR MOD(number,1000) IN (80,81,82,88,443)') if force_avoided_ports
    self.where(nikto_results: nil).where(
        'number IN (631,8000,8008,8009,8888) OR MOD(number,1000) IN (80,81,82,88,443)').where('number NOT IN (?)', AVOID_PORTS)
  end
  
  def self.take_all_screenshots!(force_avoided_ports = false)
    queued = 0
    # Do the priority ones first
    self.not_screenshotted(force_avoided_ports).
        where('number IN (?)', SCREENSHOT_PRIORITY_PORTS).each do |port|
      port.take_screenshot!
      queued += 1
    end
    
    # And the rest later
    self.not_screenshotted(force_avoided_ports).
        where('number NOT IN (?)', SCREENSHOT_PRIORITY_PORTS).each do |port|
      port.take_screenshot!
      queued += 1
    end
    
    queued
  end
  
  def self.check_all_ssl!(force_avoided_ports = false)
    queued = 0
    self.not_ssl_checked(force_avoided_ports).each do |port|
      port.check_ssl!
      queued += 1
    end
    
    queued
  end
  
  def self.queue_nikto_scans!(force_avoided_ports = false)
    queued = 0
    self.not_nikto_scanned(force_avoided_ports).each do |port|
      port.check_nikto!
      queued += 1
    end
    
    queued
  end

  def self.to_csv(grouped = false)
    CSV.generate do |csv|
      if grouped
        csv << ['port', 'count']
        all.each do |port|
          csv << [
            port.number,
            port.count
          ]
        end
      else
        csv << ['host', 'port', 'region', 'product', 'version', 'extra']
        all.each do |port|
          if port.ip_address
            csv << [
              port.ip_address.to_s,
              port.number,
              port.ip_address.region.name,
              port.product,
              port.version,
              port.extra,
            ]
          end
        end
      end
    end
  end
end
