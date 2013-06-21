class CreateEvents < ActiveRecord::Migration
  def self.up
      create_table "events" do |t|
        t.column :branch,                    :string, :limit => 50
        t.column :session_id,                :string, :limit => 40
        t.column :caller_id,                 :string, :limit => 50
        t.column :page_id,                   :integer
        t.column :action_id,                 :integer
        t.column :identifier,                :string
        t.column :option,                    :integer
        t.timestamps
      end
      add_index :events, :caller_id
    end

  def down
    remove_index :events, :caller_id
    drop_table "events"
  end
end
