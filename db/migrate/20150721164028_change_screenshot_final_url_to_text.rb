class ChangeScreenshotFinalUrlToText < ActiveRecord::Migration
  def change
    change_column :screenshots, :final_url, :text
  end
end
