class CreateAlertedMessages < ActiveRecord::Migration
  def up
    create_table :alerted_messages do |t|
      t.integer  :branch_id
      t.string  :message
      t.string :delivered_to
      t.timestamps
    end
    add_index :alerted_messages, [:branch_id,:created_at]
  end

  def down
    remove_index :alerted_messages, [:branch_id,:created_at]
    drop_table :alerted_messages
  end
end
