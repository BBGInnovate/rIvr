class AddFlagBranches < ActiveRecord::Migration
  def up
    add_column :branches, :country_flag_url, :string
    add_column :branches, :contact, :string
    add_column :branches, :ivr_call_number, :string, :limit=>20
    add_column :branches, :message_time_span, :smallint # number of messages in last message_time_span days
  end

  def down
    remove_column :branches, :country_flag_url
    remove_column :branches, :contact
    remove_column :branches, :ivr_call_number
    remove_column :branches, :message_time_span
  end
end
