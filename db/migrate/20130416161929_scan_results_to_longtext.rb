class ScanResultsToLongtext < ActiveRecord::Migration
  def change
    change_column :scans, :results, :text, :limit => 4294967295
  end
end
