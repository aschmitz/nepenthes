class RemoveIpAddressesTags < ActiveRecord::Migration
  def up
    remove_column :ip_addresses, :tag_id
    remove_column :ip_addresses, :tags
  end

  def down
    add_column :ip_addresses, :tag_id, :integer
    add_column :ip_addresses, :tags, :string
  end
end
