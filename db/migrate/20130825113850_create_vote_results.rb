class CreateVoteResults < ActiveRecord::Migration
  def up
    create_table :vote_results do |t|
      t.integer  :voting_session_id
      t.integer  :result
      t.boolean :is_active, :default => true
      t.string :session_id, :limit => 40
      t.string :caller_id, :limit => 50
      t.integer  :branch_id
      t.timestamps
    end
    add_index :vote_results, [:branch_id,:voting_session_id], :unique => false
  end

  def down
    remove_index :vote_results, [:branch_id,:voting_session_id]
    drop_table :vote_results 
  end
end
