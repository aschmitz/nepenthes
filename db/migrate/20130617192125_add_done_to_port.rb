class AddDoneToPort < ActiveRecord::Migration
  def change
    add_column :ports, :done, :boolean
  end
end
