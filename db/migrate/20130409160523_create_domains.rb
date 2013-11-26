class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :name
      t.belongs_to :parent

      t.timestamps
    end
    add_index :domains, :parent_id
  end
end
