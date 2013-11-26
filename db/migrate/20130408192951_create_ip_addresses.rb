class CreateIpAddresses < ActiveRecord::Migration
  def change
    create_table :ip_addresses do |t|
      t.string :tags
      t.belongs_to :region
      t.belongs_to :tag

      t.timestamps
    end
    add_index :ip_addresses, :region_id
    add_index :ip_addresses, :tag_id
  end
end
