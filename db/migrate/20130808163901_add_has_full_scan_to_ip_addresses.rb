class AddHasFullScanToIpAddresses < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :has_full_scan, :boolean, default: false
  end
end
