class AddStatusBranches < ActiveRecord::Migration
  def up
    add_column :branches, :status, :string, :limit=>16
    add_column :branches, :client_ip_address, :string, :limit=>20
  end

  def down
    remove_column :branches, :status
    remove_column :branches, :client_ip_address
  end
end
