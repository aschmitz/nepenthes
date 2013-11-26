class CreatePorts < ActiveRecord::Migration
  def change
    create_table :ports do |t|
      t.integer :number
      t.belongs_to :ip_address
      t.belongs_to :scan
      t.string :product
      t.string :version
      t.text :extra
      t.timestamps
    end
    # From http://stackoverflow.com/a/12514828
    # This doesn't work in SQLite3, as its integer type is just INTEGER.
    # change_column :ports, :id , 'bigint NOT NULL AUTO_INCREMENT'
  end
end
