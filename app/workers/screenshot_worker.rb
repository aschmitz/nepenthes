require 'open3'

$SCREENSHOT_SCRIPT_PATH = File.dirname(__FILE__)+'/screenshot/get_screenshot.js'

class ScreenshotWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :himem_fast
  
  def perform(id, url)
    encoded_image, status = Open3.capture2($TIMEOUT_PATH, '20',
        $PHANTOMJS_PATH, '--ignore-ssl-errors=yes', $SCREENSHOT_SCRIPT_PATH,
        url)
    
    if status == 0
      Sidekiq::Client.enqueue(ScreenshotResults, id, encoded_image)
    elsif status.exitstatus == 124
      # Timeout
      logger.info { "phantomjs timed out, reporting failure." }
      Sidekiq::Client.enqueue(ScreenshotResults, id, 'failed')
    else
      logger.info { "phantomjs died, status: #{status}" }
      Sidekiq::Client.enqueue(ScreenshotWorker, id, url)
    end
  end
end
