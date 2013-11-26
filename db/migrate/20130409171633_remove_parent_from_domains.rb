class RemoveParentFromDomains < ActiveRecord::Migration
  def up
    remove_column :domains, :parent_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Too lazy.'
  end
end
