# This assumes every screenshotable is a port -- !
class MoveFinalUrlToScreenshots < ActiveRecord::Migration
  def up
    add_column :screenshots, :final_url, :string
    update "UPDATE screenshots SET final_url = (SELECT ports.final_url FROM ports where ports.id = screenshots.screenshotable_id)"
    remove_column :ports, :final_url
  end

  def down
    add_column :ports, :final_url, :string
    update "UPDATE ports SET final_url = (SELECT screenshots.final_url FROM screenshots where ports.id = screenshots.screenshotable_id)"
    # should we group down to a scalar somehow? this may only work in mysql
    remove_column :screenshots, :final_url
  end
end
