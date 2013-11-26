class AddOptionsToScans < ActiveRecord::Migration
  def change
    add_column :scans, :options, :text
  end
end
