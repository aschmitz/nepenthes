class ScreenshotsController < ApplicationController
  def index
    if params[:distinct] == 'true'
      @screenshots = Screenshot.group('data_hash').page(params[:page]).per(100)
    else
      @screenshots = Screenshot.order('data_hash').page(params[:page]).per(100)
    end
  end

  def show
    screenshot = Screenshot.find_by_id(params[:id])
    send_data screenshot.data, type: 'image/png', disposition: 'inline'
  end
end
