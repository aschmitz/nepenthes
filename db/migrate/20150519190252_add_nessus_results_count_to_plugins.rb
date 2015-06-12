class AddNessusResultsCountToPlugins < ActiveRecord::Migration
  def self.up
    add_column :nessus_plugins, :nessus_results_count, :integer, :default => 0
    
    NessusPlugin.reset_column_information
    NessusPlugin.find(:all).each do |p|
      NessusPlugin.update_counters p.id, nessus_results_count: p.nessus_results.count
    end
  end

  def self.down
    remove_column :nessus_plugins, :nessus_results_count
  end
end
