class AddSettingsToPortAndIpAddress < ActiveRecord::Migration
  def change
    add_column :ports, :settings, :text, limit: 50.megabytes
    add_column :ip_addresses, :settings, :text, limit: 50.megabytes
  end
end
