class AddDataHashToScreenshot < ActiveRecord::Migration
  class Screenshot < ActiveRecord::Base
  end

  def change
    add_column :screenshots, :data_hash, :string
    Screenshot.reset_column_information
    reversible do |dir|
      dir.up do
        Screenshot.where.not(data: nil).find_each do |x|
          x.data_hash = OpenSSL::Digest::MD5.hexdigest x.data
          x.save!
        end
      end
    end
  end
end
