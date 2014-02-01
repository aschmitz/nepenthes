class AddDataHashToScreenshot < ActiveRecord::Migration
  def change
    add_column :screenshots, :data_hash, :string
  end
end
