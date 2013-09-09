class AddTimeSpanOptions < ActiveRecord::Migration
  def up
    Option.create :name=>'message_time_span', :value=>'7', :branch_id=>0
  end

  def down
    o = Option.find_by_name 'message_time_span'
    o.destroy if o
  end
end
