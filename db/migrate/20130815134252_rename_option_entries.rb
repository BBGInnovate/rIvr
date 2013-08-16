class RenameOptionEntries < ActiveRecord::Migration
  def up
    rename_column :entries, :option, :forum_type
  end

  def down
    rename_column :entries, :forum_type, :option
  end
end
