class HostnameResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(results)
    results.each do |result|
      id, hostname_data = result
      
      ip_address = IpAddress.find(id)
      next unless ip_address
      ip_address.hostname = hostname_data
      ip_address.save!
    end
  end
end
