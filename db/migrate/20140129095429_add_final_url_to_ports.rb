class AddFinalUrlToPorts < ActiveRecord::Migration
  def change
    add_column :ports, :final_url, :string
  end
end
