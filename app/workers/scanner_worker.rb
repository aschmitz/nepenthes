require 'open3'

class ScannerWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_slow
  
  def perform(id, host, opts)
    full_options = ['nmap', '-oX', '-', opts, host].flatten
    stdout_str, status = Open3.send(:capture2, *full_options)
    if status == 0
      Sidekiq::Client.enqueue(ScannerResults, id, stdout_str, false)
    else
      # nmap didn't finish properly (probably killed), try again later.
      Sidekiq::Client.enqueue(ScannerWorker, id, host, opts)
    end
  end
end
