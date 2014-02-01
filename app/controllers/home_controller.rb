class HomeController < ApplicationController
  def index
  end
  
  def action
    case params[:id]
    when 'ipaddress_quick'
      count = IpAddress.queue_quick_scans!
      flash[:success] = "Queued quick scans for #{count} hosts."
    when 'ipaddress_full'
      count = IpAddress.queue_full_scans!
      flash[:success] = "Queued full scans for #{count} hosts."
    when 'ipaddress_hostname'
      count = IpAddress.queue_hostname_checks!
      flash[:success] = "Queued hostname checks for #{count} hosts."
    when 'ipaddress_rescan'
      count = IpAddress.queue_rescans! params[:timeout]
      flash[:success] = "Re-queued full scans for #{count} hosts."
    when 'port_ssl'
      count = Port.check_all_ssl!
      flash[:success] = "Queued SSL checks for #{count} ports."
    when 'port_screenshot'
      count = Port.take_all_screenshots!
      flash[:success] = "Queued screenshots for #{count} ports."
    when 'port_nikto'
      count = Port.queue_nikto_scans!
      flash[:success] = "Queued Nikto scans for #{count} ports."
    else
      flash[:error] = 'Unknown action.'
    end
    
    redirect_to root_path
  end
  
  def screenshots
    @screenshots = Screenshot
    @screenshots = @screenshots.group('data_hash').page(params[:page]).per(100)
  end
end
