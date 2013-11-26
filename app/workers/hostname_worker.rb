require 'resolv'

class HostnameWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(id, host)
    begin
      hostname_data = Resolv.getname(host)
    rescue Resolv::ResolvError
      hostname_data = ''
    end
    Sidekiq::Client.enqueue(HostnameResults, id, hostname_data)
  end
end
