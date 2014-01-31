class ChangePortsNiktoResults < ActiveRecord::Migration
  def change
    change_column :ports, :nikto_results, :text, :limit => 2147483647
  end
end
