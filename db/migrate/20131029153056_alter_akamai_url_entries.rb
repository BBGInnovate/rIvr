class AlterAkamaiUrlEntries < ActiveRecord::Migration
  def up
    rename_column(:entries, :akamai_url, :ftp_url)
  end

  def down
    rename_column(:entries, :ftp_url, :akamai_url)
  end
end
