class ScreenshotsController < ApplicationController
  def index
    @screenshots = Screenshot.group('data_hash').page(params[:page]).per(100)
  end

  def show
    screenshot = Screenshot.find_by_id(params[:id])
    send_data screenshot.data, type: 'image/png', disposition: 'inline'
  end
end
