class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index :ports, :ip_address_id
    add_index :ports, :number
    add_index :ports, :done
  end
end
