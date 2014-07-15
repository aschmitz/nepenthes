require 'net/ping'

class PingWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(id, host)
    ping = Net::Ping::External.new(host)
    ping.timeout = 5
    
    result = ping.ping?
    
    Sidekiq::Client.enqueue(PingResults, id, result, ping.duration)
  end
end
