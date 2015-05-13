require 'base64'

class ScreenshotResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, result)
    screenshot = Screenshot.find_by_id(id)
    return unless screenshot
    
    if screenshot.screenshotable.is_a?(Port)
      port = screenshot.screenshotable
      port.screenshotted = true
      port.save
    end
    
    lines = result.split "\n"
    final_url = lines[0]
    encoded_image = lines[1]
    if final_url.strip == 'failed' or encoded_image.blank?
      # If we failed to take the screenshot, we'll just delete it to avoid
      #  having it show up in other pages.
      screenshot.destroy
    else
      image = Base64.decode64(encoded_image)

      screenshot.final_url = final_url
      screenshot.data = image
      screenshot.data_hash = OpenSSL::Digest::MD5.hexdigest image
      screenshot.save!
    end
  end
end
