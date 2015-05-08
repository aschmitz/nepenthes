class AddRandToIpAddress < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :rand, :float, default: nil
    
    IpAddress.connection.execute("UPDATE ip_addresses SET rand = RAND()")
  end
end
