class AddRoleToUsers < ActiveRecord::Migration
  def up
    add_column :users, :role, :string
    # 'admin', or braches : 'oddi', 'mali'
  end
  def down
    remove_column :users, :role
  end
end
