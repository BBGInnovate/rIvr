class Event < ActiveRecord::Base
  def to_label
    "Event Log"
  end
  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
end