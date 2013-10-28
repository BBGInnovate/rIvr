class AddAkamaiBranches < ActiveRecord::Migration
  def up
    add_column :branches, :akamai_server, :string
    add_column :branches, :akamai_user, :string
    add_column :branches, :akamai_pwd, :string
    add_column :branches, :akamai_path, :string
    
    Branch.reset_column_information
    Branch.all.each do |b| 
      # b.akamai_server = 'voiceofame2.upload.akamai.com'
      # b.akamai_user = 'masset2'
      # b.akamai_pwd = 'masset2!media'
      # b.akamai_path = '/8475/MediaAssets2/bbg/ivr/'
      # b.save
    end
    
  end

  def down
    remove_column :branches, :akamai_server
    remove_column :branches, :akamai_user
    remove_column :branches, :akamai_pwd
    remove_column :branches, :akamai_path
  end
end
