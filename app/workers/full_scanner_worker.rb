require 'open3'

class FullScannerWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_slow
  
  def perform(id, host, ping_duration = nil, timeout=30)
    # From http://nmap.org/book/man-performance.html:
    #  Look at the maximum round trip time out of ten packets or so. You might
    #  want to double that for the --initial-rtt-timeout and triple or
    #  quadruple it for the --max-rtt-timeout. I generally do not set the
    #  maximum RTT below 100 ms, no matter what the ping times are. Nor do I
    #  exceed 1000 ms.
    
    # We only ping once, but we'll use similar heuristics.
    if ping_duration
      initial_rtt_timeout = ping_duration * 1000 * 2
      max_rtt_timeout = ping_duration * 1000 * 5 # Yes, 5. Handles ping jitter.
      initial_rtt_timeout = [initial_rtt_timeout, 100].max.to_i
      max_rtt_timeout = [max_rtt_timeout, 1000].min.to_i
    else
      initial_rtt_timeout = 100
      max_rtt_timeout = 500
    end
    full_options = ['nmap', '-Pn', '-oX', '-', '-p-',
      '--initial-rtt-timeout='+initial_rtt_timeout.to_s+'ms',
      '--max-rtt-timeout='+max_rtt_timeout.to_s+'ms',
      '--max-retries=2', "--host-timeout=#{timeout}m", '-v', '-sV',
      '-sT', '--version-light', host]
    stdout_str, status = Open3.send(:capture2, *full_options)
    if status == 0
      Sidekiq::Client.enqueue(ScannerResults, id, stdout_str, true)
    else
      # nmap didn't finish properly (probably killed), try again later.
      logger.info { "nmap died, status: #{status}" }
      Sidekiq::Client.enqueue(FullScannerWorker, id, host, timeout)
    end
  end
end
