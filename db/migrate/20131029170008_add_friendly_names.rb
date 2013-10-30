class AddFriendlyNames < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.column_exists?('branches', 'friendly_name')
      add_column :branches, :friendly_name, :string
    end
    if !ActiveRecord::Base.connection.column_exists?('voting_sessions', 'friendly_name')
      add_column :voting_sessions, :friendly_name, :string
    end
    Branch.reset_column_information
    VotingSession.reset_column_information
    Branch.all.each do |b| 
      b.friendly_name = b.name.parameterize
      b.save
    end
    
    VotingSession.all.each do |b| 
      b.friendly_name = b.name.parameterize
      b.save
    end
    
  end

  def down
    remove_column :branches, :friendly_name
    remove_column :voting_sessions, :friendly_name
  end
end
