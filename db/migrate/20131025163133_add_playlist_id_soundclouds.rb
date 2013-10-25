class AddPlaylistIdSoundclouds < ActiveRecord::Migration
  def up
    add_column :soundclouds, :playlist_id, :integer
  end

  def down
    remove_column :soundclouds, :playlist_id
  end
end
