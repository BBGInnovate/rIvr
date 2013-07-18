class AlterEntriesSoundcloud < ActiveRecord::Migration
  def up
    add_column :entries, :title, :string
    add_column :entries, :soundcloud_url, :string
  end

  def down
    remove_column :entries, :title
    remove_column :entries, :soundcloud_url
  end
end
