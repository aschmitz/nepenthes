class CreateScreenshots < ActiveRecord::Migration
  def change
    create_table :screenshots do |t|
      t.string  :url
      t.binary  :data, limit: 5.megabytes
      t.integer :screenshotable_id
      t.string  :screenshotable_type
      t.timestamps
    end
  end
end
