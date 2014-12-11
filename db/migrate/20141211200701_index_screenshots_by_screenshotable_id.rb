class IndexScreenshotsByScreenshotableId < ActiveRecord::Migration
  def change
    add_index :screenshots, :screenshotable_id
  end
end
