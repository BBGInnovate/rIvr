class AddCurrentVotingSessions < ActiveRecord::Migration
  def up
    add_column :voting_sessions, :current, :boolean
  end

  def down
    remove_column :voting_sessions
  end
end
