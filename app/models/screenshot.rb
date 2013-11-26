class Screenshot < ActiveRecord::Base
  attr_accessible :url, :data
  belongs_to :screenshotable, polymorphic: true
  
  def take!
    return if self.data
    
    Sidekiq::Client.enqueue(ScreenshotWorker, self.id, self.url)
  end
end
