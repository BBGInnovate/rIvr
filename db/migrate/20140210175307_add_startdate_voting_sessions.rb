class AddStartdateVotingSessions < ActiveRecord::Migration
  def up
     add_column :voting_sessions, :start_date, :datetime
     add_column :voting_sessions, :end_date, :datetime
  end

  def down
     remove_column :voting_sessions, :start_date
     remove_column :voting_sessions, :end_date,
  end
end
