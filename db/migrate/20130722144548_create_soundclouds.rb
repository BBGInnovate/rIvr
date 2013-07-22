class CreateSoundclouds < ActiveRecord::Migration
  def up
    create_table :soundclouds do |t|
      t.string  :title, :limit=>60, :null => false
      t.string  :url, :limit=>255, :null => false
      t.string  :genre, :limit=>40
      t.string  :description, :limit=>255
      t.integer :entry_id
      t.integer :track_id
      t.timestamps
    end
  end

  def down
    drop_table "soundclouds"
  end
end
