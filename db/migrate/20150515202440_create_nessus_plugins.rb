class CreateNessusPlugins < ActiveRecord::Migration
  def change
    create_table :nessus_plugins do |t|
      t.string :name
      t.integer :severity
      t.timestamps
    end
  end
end
