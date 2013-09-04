class BranchesUsers < ActiveRecord::Migration
  def up
    create_table :branches_users, :force => true,  :id => false do |t|
      t.integer :branch_id, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
    add_index :branches_users, [:branch_id, :user_id], :unique => true
  end

  def down
    remove_index :branches_users, [:branch_id, :user_id]
  end
end
