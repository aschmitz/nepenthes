class DynamicController < ApplicationController
  def screenshot
    screenshot = Screenshot.find_by_id(params[:id])
    send_data screenshot.data, type: 'image/png', disposition: 'inline'
  end
end
