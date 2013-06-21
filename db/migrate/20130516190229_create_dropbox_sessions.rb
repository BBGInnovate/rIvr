class CreateDropboxSessions < ActiveRecord::Migration
  def up
    create_table :dropbox_sessions do |t|
      t.string :token, :null => false
      t.string :secret, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :dropbox_sessions 
  end
end
