class HostnameResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, hostname_data)
    ip_address = IpAddress.find_by_id(id)
    return unless ip_address
    ip_address.hostname = hostname_data
    ip_address.save!
  end
end
