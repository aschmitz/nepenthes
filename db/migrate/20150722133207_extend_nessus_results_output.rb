class ExtendNessusResultsOutput < ActiveRecord::Migration
  def change
    change_column :nessus_results, :output, :text, limit: 2147483647
  end
end
