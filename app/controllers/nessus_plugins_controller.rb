class NessusPluginsController < ApplicationController
  def index
  end
  
  def show
    @plugin = NessusPlugin.find(params[:id])
  end
end
