class RemoveDataFromScreenshots < ActiveRecord::Migration
  def change
    remove_column :screenshots, :data
  end
end
