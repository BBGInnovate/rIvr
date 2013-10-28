class AddSoundcloudBranches < ActiveRecord::Migration
   def up
    add_column :branches, :soundcloud_client_id, :string
    add_column :branches, :soundcloud_client_secret, :string
    add_column :branches, :soundcloud_access_token, :string
    Branch.reset_column_information
    
    Branch.all.each do |b| 
      # b.soundcloud_client_id = '6691b64f50b95655fab93e0b9bb5dba1'
      # b.soundcloud_client_secret = '31749231dbf136af037d19f5b33ac110'
      # b.soundcloud_access_token = '1-45851-51237388-03f7514b54222cf'
      # b.save
    end
  end

  def down
    remove_column :branches, :soundcloud_client_id
    remove_column :branches, :soundcloud_client_secret
    remove_column :branches, :soundcloud_access_token
  end
end
