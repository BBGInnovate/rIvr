class CreateVoteResults < ActiveRecord::Migration
  def up
    create_table :vote_results do |t|
      t.string  :identifier, :limit=>40
      t.integer  :result
      t.boolean :is_active, :default => true
      t.integer  :branch_id
      t.timestamps
    end
    add_index :vote_results, :branch_id, :unique => false
  end

  def down
    remove_index :vote_results, :branch_id
    drop_table :vote_results 
  end
end
