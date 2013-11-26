class ChangeIpAddressAddressToInteger < ActiveRecord::Migration
  def up
    # Most databases aren't happy with 128-bit integers for some reason.
    change_column :ip_addresses, :address, :integer, :limit => 4, :default => 0
  end

  def down
    change_column :ip_addresses, :address, :binary, :limit => 255
  end
end
