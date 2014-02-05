require 'open3'

class NiktoWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :himem_slow
  
  def perform(id, host, port, ssl)
    nikto_data, status = Open3.capture2($NIKTO_PATH,
          '-host', "#{host}", '-port', "#{port}", '-C', 'all', ssl ? '-ssl' : '-nossl')
        
    if status == 0
      Sidekiq::Client.enqueue(NiktoResults, id, nikto_data)
    else
      # nikto didn't finish properly (probably killed), try again later.
      logger.info { "nikto died, status: #{status}" }
      Sidekiq::Client.enqueue(NiktoWorker, id, host, port, ssl)
    end
  end
end
