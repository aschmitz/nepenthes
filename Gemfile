source 'https://rubygems.org'
gem 'rails', '~> 4.2.0'

# Rails 4.0 dropped this, we'll put it back for now.
gem 'protected_attributes'

# Remote workers
gem 'sidekiq'
gem 'sidekiq_status'
gem 'redis-namespace'
gem 'slim'
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', '>= 1.3.0', :require => nil

# Tags, necessary in both environments because of the helpers.
gem 'acts-as-taggable-on'

# XML parsing
gem 'nokogiri'

# Used for pinging, has to be in both as the frontend still loads workers.
gem 'net-ping'

# Used for Nessus.
gem 'rest-client'

group :remote do
  # Needed for the in-memory SQLite stub. Pointless, but easier than patching
  #  ActiveRecord out of everything, or Sidekiq to not load models.
  gem 'sqlite3'
end

group :local do
  # We'll just standardize on MySQL.
  gem 'mysql2', '~> 0.3.10'
  
  # Bootstrap
  gem 'therubyracer'
  gem 'less-rails' #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
  gem 'twitter-bootstrap-rails', '~> 2.2.6'
  
  # Network gems
  gem 'netaddr', '~> 1.5'
  
  # Pagination
  gem 'kaminari'
  
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  
  # Unicorn as a server
  gem 'unicorn'
end
