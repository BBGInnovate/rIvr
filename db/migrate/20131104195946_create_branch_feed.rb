class CreateBranchFeed < ActiveRecord::Migration
  def up
    create_table "branch_feeds" do |t|
      t.integer :branch_id
      t.integer :forum_session_id
      t.integer :feed_limit
      t.string :feed_source
      t.string :feed_url
      t.timestamps
    end
    add_index :branch_feeds, :branch_id
  end

  def down
     remove_index :branch_feeds, :branch_id
     drop_table "branch_feeds"
  end
end
