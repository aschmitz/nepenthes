require 'base64'

class NiktoResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, nikto_data)
    port = Port.find_by_id(id)
    port.nikto_results = nikto_data
    port.save!
  end
end
