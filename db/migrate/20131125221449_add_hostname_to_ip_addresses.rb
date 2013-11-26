class AddHostnameToIpAddresses < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :hostname, :string
  end
end
