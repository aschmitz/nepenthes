class AddTaggingsIndex < ActiveRecord::Migration
  def change
    add_index :taggings, [:tag_id, :taggable_id]
  end
end
