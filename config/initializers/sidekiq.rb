Sidekiq.configure_server do |config|
  config.redis = { namespace: 'resque', timeout: 30 }

  config.server_middleware do |chain|
    # Handles scheduling. Find the SchedulingMiddleware class in lib/scheduling_middleware.rb
    chain.add SchedulingMiddleware
  end
end
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'resque' }
end
