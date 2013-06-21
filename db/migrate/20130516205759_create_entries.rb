class CreateEntries < ActiveRecord::Migration
  def up
    create_table :entries do |t|
      t.string :file_location
      t.string :public_url
      t.integer :size
      t.integer :length
      t.string :mime_type, :limit => 40
      t.string :dropbox_dir
      t.string :dropbox_file
      t.string :phone_number, :limit => 50
      t.string :branch, :limit => 50
      t.integer :you_tube_upload_status
      t.boolean :downloaded_from_sky_drive
      t.boolean :is_private
      t.string :you_tube_video_id, :limit=>400
      t.integer :cloud_storage_upload_status
      t.integer :facebook_upload_status
      t.timestamps
    end
    add_index :entries, [:branch,:dropbox_file], :unique => true
  end

  def down
    remove_index :entries, [:branch,:dropbox_file]
    drop_table :entries
  end
end
