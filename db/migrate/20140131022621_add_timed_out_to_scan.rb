class AddTimedOutToScan < ActiveRecord::Migration
  def change
    add_column :scans, :timed_out, :boolean
  end
end
