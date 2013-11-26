class AddSslToPort < ActiveRecord::Migration
  class Port < ActiveRecord::Base
  end
  
  def up
    add_column :ports, :ssl, :boolean
    add_index :ports, :ssl
    Port.reset_column_information
    Port.all.each do |port|
      port.ssl = port.settings.delete('ssl')
    end
  end
  def down
    Port.all.each do |port|
      port.settings['ssl'] = port.ssl
    end
    remove_index :ports, :ssl
    remove_column :ports, :ssl
  end
end
