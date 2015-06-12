class AddAttributesToNessusPlugins < ActiveRecord::Migration
  def change
    add_column :nessus_plugins, :extra, :text, limit: (2**32)-1
  end
end
