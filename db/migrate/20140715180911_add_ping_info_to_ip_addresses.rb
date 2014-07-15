class AddPingInfoToIpAddresses < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :pinged, :boolean, nil: false, default: false
    add_column :ip_addresses, :pingable, :boolean
    add_column :ip_addresses, :ping_duration, :float
  end
end
