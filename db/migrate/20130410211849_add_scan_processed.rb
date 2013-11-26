class AddScanProcessed < ActiveRecord::Migration
  def change
    add_column :scans, :processed, :boolean, :default => false, :null => false
  end
end
