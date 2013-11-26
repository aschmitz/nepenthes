class ChangeIpaddressToBinary < ActiveRecord::Migration
  class IpAddress < ActiveRecord::Base
  end
  
  def up
    add_column :ip_addresses, :address, :binary, :limit => 16
    IpAddress.reset_column_information
    IpAddress.all.each do |ipaddr|
      ipaddr.address_bin = NetAddr::CIDR.create(ipaddr.address).to_i(:ip)
      ipaddr.save!
    end
    add_index :ip_addresses, :address, :unique => true, :length => 16
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Too lazy.'
  end
end
