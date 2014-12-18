class RedisResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, results)
    port = Port.find_by_id(id)
    return unless port
    unless port.extra.to_s.empty?
      port.extra += "\n"
    end
    port.extra = port.extra.to_s + results
    port.save!
  end
end
