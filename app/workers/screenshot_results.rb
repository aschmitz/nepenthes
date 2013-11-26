require 'base64'

class ScreenshotResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, encoded_image)
    screenshot = Screenshot.find_by_id(id)
    return unless screenshot
    
    if screenshot.screenshotable.is_a?(Port)
      port = screenshot.screenshotable
      port.screenshotted = true
      port.save
    end
    
    if encoded_image.strip == 'failed' or encoded_image == ''
      # If we failed to take the screenshot, we'll just delete it to avoid
      #  having it show up in other pages.
      screenshot.destroy
    else
      image = Base64.decode64(encoded_image)
      screenshot.data = image
      screenshot.save!
    end
  end
end
