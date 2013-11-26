class AddNotesToPort < ActiveRecord::Migration
  def change
    add_column :ports, :notes, :text
  end
end
