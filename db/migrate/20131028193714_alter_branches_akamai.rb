class AlterBranchesAkamai < ActiveRecord::Migration
  def up
    rename_column(:branches, :akamai_server, :ftp_server)
    rename_column(:branches, :akamai_user, :ftp_user)
    rename_column(:branches, :akamai_pwd, :ftp_pwd)
    rename_column(:branches, :akamai_path, :ftp_path)
    add_column :branches, :ftp_url_base, :string
  end

  def down
    if ActiveRecord::Base.connection.column_exists?('branches', 'ftp_url_base')
      remove_column :branches, :ftp_url_base
    end
    rename_column(:branches, :ftp_server, :akamai_server)
    rename_column(:branches, :ftp_user, :akamai_user)
    rename_column(:branches, :ftp_pwd, :akamai_pwd)
    rename_column(:branches, :ftp_path, :akamai_path)
  end
end
