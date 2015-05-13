require 'fileutils'

class Screenshot < ActiveRecord::Base
  attr_accessible :url
  belongs_to :screenshotable, polymorphic: true
  before_destroy :delete_file
  
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
  
  def file_path
    prefix = self.id / 10000
    suffix = self.id % 10000
    dir = Rails.root.join('system', 'screenshots', prefix.to_s)
    FileUtils.mkdir_p(dir)
    dir.join(suffix.to_s)
  end
  
  def data=(d)
    File.open(self.file_path, 'w:ASCII-8BIT') do |f|
      f.write(d)
    end
  end
  
  def data
    begin
      File.open(self.file_path, 'r:ASCII-8BIT') do |f|
        f.read
      end
    rescue
      nil
    end
  end
  
  def delete_file
    begin
      File.unlink(self.file_path)
      return true
    rescue
      return true
    end
  end
end
