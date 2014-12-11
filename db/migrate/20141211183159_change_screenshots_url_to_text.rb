class ChangeScreenshotsUrlToText < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        change_column :screenshots, :url, :text
      end

      dir.down do
        change_column :screenshots, :url, :string
      end
    end
  end
end
