class NessusResult < ActiveRecord::Base
  belongs_to :ip_address
  belongs_to :nessus_plugin, counter_cache: true
  store :ports, coder: JSON
  
  attr_accessible :nessus_plugin_id, :ports, :output, :severity
end
