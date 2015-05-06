class AddTaggableIndexForItems < ActiveRecord::Migration
  def change
    add_index :taggings, [:taggable_id, :taggable_type]
  end
end
