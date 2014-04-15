class AddSettingsToPortAndIpAddress < ActiveRecord::Migration
  def change
    add_column :ports, :settings, :text, limit: 1.gigabytes-1
    add_column :ip_addresses, :settings, :text, limit: 1.gigabytes-1
  end
end
