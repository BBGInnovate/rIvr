class AddStatusBranches < ActiveRecord::Migration
  def up
    add_column :branches, :status, :string, :limit=>16
  end

  def down
    remove_column :branches, :status
  end
end
