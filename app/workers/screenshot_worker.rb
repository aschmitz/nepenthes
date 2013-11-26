require 'open3'

$SCREENSHOT_SCRIPT_PATH = File.dirname(__FILE__)+'/screenshot/get_screenshot.js'

class ScreenshotWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :himem_fast
  
  def perform(id, url)
    encoded_image, status = Open3.capture2($TIMEOUT_PATH, '20',
        $PHANTOMJS_PATH, '--ignore-ssl-errors=yes', $SCREENSHOT_SCRIPT_PATH,
        url)
    
    Sidekiq::Client.enqueue(ScreenshotResults, id, encoded_image)
  end
end
