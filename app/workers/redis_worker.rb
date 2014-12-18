require 'redis'

class RedisWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(id, host, port)
    accepted_keys = %w{redis_version used_memory_human os keyspace_hits role
      master_host master_port master_link_status connected_slaves}
    
    results = ''
    redis = Redis.new(host: host, port: port)
    redis.info.each do |key, value|
      if accepted_keys.include?(key)
        results += "#{key}: #{value}\n"
      end
      
      if match = /^db(\d+)$/.match(key)
        results += "#{key}: #{value}\n"
        db = match[1]
        keys_count = /keys=(\d+)[^\d]/.match(value)[1].to_i
        redis.select(db)
        results += "#{key} sample keys: "
        if keys_count < 100
          # If there are few keys, just get them all.
          keys = redis.keys('*').sample(4)
        else
          keys = (0..3).map { redis.randomkey }
        end
        results += keys.map(&:inspect).join(' ')+"\n"
      end
    end
    
    Sidekiq::Client.enqueue(RedisResults, id, results)
  end
end
