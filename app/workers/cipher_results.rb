require 'base64'

class SslResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, ssl_data)
    port = Port.find_by_id(id)
    port.notes = ssl_data
    port.save!
  end
end
