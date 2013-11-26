class AddScreenshottedToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :screenshotted, :boolean, default: false
    add_index :ports, :screenshotted
  end
end
