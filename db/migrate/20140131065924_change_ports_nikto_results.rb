class ChangePortsNiktoResults < ActiveRecord::Migration
  def up
    change_column :ports, :nikto_results, :text, :limit => 2147483647
  end

  def down
    change_column :ports, :nikto_results, :text
  end
end
