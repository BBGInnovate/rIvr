class AddForumSessionIdEntries < ActiveRecord::Migration
  def up
    # the same as voting_session_id
    add_column :entries, :forum_session_id, :integer
  end

  def down
    remove_column :entries, :forum_session_id
  end
end
