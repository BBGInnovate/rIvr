class AddAkamaiUrlEntries < ActiveRecord::Migration
  def up
    rename_column :entries, :file_location, :akamai_url
  end

  def down
    rename_column :entries, :akamai_url, :file_location
  end
end
