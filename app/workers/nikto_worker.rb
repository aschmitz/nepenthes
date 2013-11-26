require 'open3'

class NiktoWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :himem_slow
  
  def perform(id, host, port, ssl)
    nikto_data, status = Open3.capture2($NIKTO_PATH,
          '-host', "#{host}", '-port', "#{port}", '-C', 'all', ssl ? '-ssl' : '-nossl')
        
    Sidekiq::Client.enqueue(NiktoResults, id, nikto_data)
  end
end
