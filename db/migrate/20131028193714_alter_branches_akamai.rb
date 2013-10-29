class AlterBranchesAkamai < ActiveRecord::Migration
  def up
    rename_column(:branches, :akamai_server, :ftp_server)
    rename_column(:branches, :akamai_user, :ftp_user)
    rename_column(:branches, :akamai_pwd, :ftp_pwd)
    rename_column(:branches, :akamai_path, :ftp_path)
  end

  def down
  end
end
