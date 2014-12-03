class Screenshot < ActiveRecord::Base
  attr_accessible :url, :data
  belongs_to :screenshotable, polymorphic: true
  
  def take!
    return if self.data
    
    Sidekiq::Client.enqueue(ScreenshotWorker, self.id, self.url)
  end

  def all_ips
    IpAddress.joins(:ports => :screenshots).where(screenshots: {data_hash: data_hash}).distinct
  end
  
  def all_ports
    Port.joins(:screenshots).where(screenshots: {data_hash: data_hash}).distinct
  end
end
