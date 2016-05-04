require 'open3'

class SslWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(id, host, port)
    if $TIMEOUT_PATH == nil
      raise 'Please install coreutils.'
    end
    ssl_data, status = Open3.capture2($TIMEOUT_PATH, '2', $OPENSSL_PATH,
      's_client', '-connect', "#{host}:#{port}", '-showcerts')
    ssl_data.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace)
    Sidekiq::Client.enqueue(SslResults, id, ssl_data)
  end
end
