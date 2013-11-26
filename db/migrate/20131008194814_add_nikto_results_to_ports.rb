class AddNiktoResultsToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :nikto_results, :text
  end
end
