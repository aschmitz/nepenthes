require 'open3'

class FullScannerWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_slow
  
  def perform(id, host, timeout=30)
    full_options = ['nmap', '-Pn', '-oX', '-', '-p-', '--max-rtt-timeout=500ms',
      '--max-retries=2', "--host-timeout=#{timeout}m", '-v', '-sV', '--version-light', host]
    stdout_str, status = Open3.send(:capture2, *full_options)
    if status == 0
      Sidekiq::Client.enqueue(ScannerResults, id, stdout_str, true)
    else
      # nmap didn't finish properly (probably killed), try again later.
      Sidekiq::Client.enqueue(FullScannerWorker, id, host, timeout)
    end
  end
end
