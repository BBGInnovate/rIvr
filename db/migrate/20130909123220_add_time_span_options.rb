class AddTimeSpanOptions < ActiveRecord::Migration
  def up
    Option.create :name=>'message_time_span', :value=>'7', :branch_id=>0, :description=>'value is number of days'
    Option.create :name=>'refresh_stats', :value=>'30', :branch_id=>0, :description=>'value is number of seconds'
  end

  def down
    o = Option.find_by_branch_id_and_name 0,'message_time_span'
    o.destroy if o
    o = Option.find_by_branch_id_and_name 0,'refresh_stats'
    o.destroy if o
  end
end
