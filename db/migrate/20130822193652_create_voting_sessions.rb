class CreateVotingSessions < ActiveRecord::Migration
  def up
    create_table :voting_sessions do |t|
       t.integer :branch_id
       t.string :name, :limit=>40
       t.string :description
       t.boolean :is_active, :default=>true
       t.timestamps
    end
    add_index :voting_sessions, :branch_id
  end

  def down
    remove_index :voting_sessions, :branch_id
    drop_table :voting_sessions
  end
end
