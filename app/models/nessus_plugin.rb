class NessusPlugin < ActiveRecord::Base
  has_many :nessus_results, dependent: :delete_all,
    counter_cache: true
  store :extra, coder: JSON
end
