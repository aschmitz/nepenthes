class CreateScans < ActiveRecord::Migration
  def change
    create_table :scans do |t|
      t.belongs_to :ip_address
      t.text :results

      t.timestamps
    end
    add_index :scans, :ip_address_id
  end
end
