class Region < ActiveRecord::Base
  attr_accessible :name, :utc_end_test, :utc_start_test
  
  has_many :ip_addresses
end
