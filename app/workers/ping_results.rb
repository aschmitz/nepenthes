class PingResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, pingable, ping_duration)
    ip_address = IpAddress.find_by_id(id)
    return unless ip_address
    ip_address.pinged = true
    ip_address.pingable = pingable
    if pingable
      ip_address.ping_duration = ping_duration
    end
    ip_address.save!
  end
end
