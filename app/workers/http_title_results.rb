class HttpTitleResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, title)
    puts id
    puts title
    port = Port.find_by_id(id)
    port.extra = "#{port.extra} \n  #{title}"
    port.save!
  end
end
