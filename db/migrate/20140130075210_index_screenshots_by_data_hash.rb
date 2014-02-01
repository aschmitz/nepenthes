class IndexScreenshotsByDataHash < ActiveRecord::Migration
  def change
    add_index :screenshots, :data_hash
  end
end
