Sidekiq.configure_server do |config|
  config.redis = { namespace: 'resque', timeout: 30 }
end
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'resque' }
end
