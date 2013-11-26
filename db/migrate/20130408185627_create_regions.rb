class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.string :name
      t.float :utc_start_test
      t.float :utc_end_test

      t.timestamps
    end
  end
end
