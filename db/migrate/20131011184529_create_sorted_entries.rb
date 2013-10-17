class CreateSortedEntries < ActiveRecord::Migration
  def up
   create_table :sorted_entries do |t|
      t.integer  :branch_id
      t.integer  :entry_id
      t.string  :dropbox_file
      t.column :rank, :smallint
      t.integer  :forum_session_id
      
      t.timestamps
    end
    add_index :sorted_entries, [:branch_id,:forum_session_id], :unique => false
  end

  def down
    remove_index :sorted_entries, [:branch_id,:forum_session_id]
    drop_table :sorted_entries
  end
end
