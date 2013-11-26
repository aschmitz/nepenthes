class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_auth
  http_basic_authenticate_with(
      name: AUTH_CONFIG['username'],
      password: AUTH_CONFIG['password'])
  
  # Using pluralize inside controllers.
  # From http://www.dzone.com/snippets/using-helpers-inside
  def help
    Helper.instance
  end
  
  def require_auth
    unless AUTH_CONFIG and AUTH_CONFIG['changed']
      render text: 'You must set up config/auth.yml first.'
    end
  end

  class Helper
    include Singleton
    include ActionView::Helpers::TextHelper
  end
end
