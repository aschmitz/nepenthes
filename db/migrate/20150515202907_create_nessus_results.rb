class CreateNessusResults < ActiveRecord::Migration
  def change
    create_table :nessus_results do |t|
      t.belongs_to :ip_address
      t.belongs_to :nessus_plugin
      t.text :ports
      t.text :output
      t.integer :severity
      t.timestamps
    end
    
    add_column :ip_addresses, :has_nessus, :bool, default: false
  end
end
