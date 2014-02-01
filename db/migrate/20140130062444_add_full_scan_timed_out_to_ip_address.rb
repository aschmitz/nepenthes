class AddFullScanTimedOutToIpAddress < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :full_scan_timed_out, :boolean
  end
end
