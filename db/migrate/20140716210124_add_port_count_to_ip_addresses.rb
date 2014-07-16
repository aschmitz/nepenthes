class AddPortCountToIpAddresses < ActiveRecord::Migration
  def self.up
    add_column :ip_addresses, :ports_count, :integer, null: false, default: 0
    # reset cached counts for IP addresses with comments only
    ids = Set.new
    Port.all.each {|p| ids << p.ip_address_id}
    ids.each do |ip_id|
      IpAddress.reset_counters(ip_id, :ports)
    end
  end
  
  def self.down
    remove_column :ip_addresses, :ports_count
  end
end
