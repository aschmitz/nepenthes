class ScannerResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, results, full)
    scan = Scan.find_by_id(id)
    scan.results = results
    scan.save!
    scan.process!
    if full
      ip = scan.ip_address
      ip.has_full_scan = true
      ip.full_scan_timed_out = scan.timed_out
      ip.save!
    end
  end
end
