class Event < ActiveRecord::Base
  belongs_to :action
  def to_label
    "Event Log"
  end
  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
end