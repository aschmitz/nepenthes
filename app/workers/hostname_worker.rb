require 'resolv'

class HostnameWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(hosts)
    results = []
    hosts.each do |host_data|
      host_id, address = host_data
      begin
        hostname_data = Resolv.getname(address)
      rescue Resolv::ResolvError
        hostname_data = ''
      end
      results << [host_id, hostname_data]
    end
    Sidekiq::Client.enqueue(HostnameResults, results)
  end
end
