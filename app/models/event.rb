class Event < ActiveRecord::Base
  belongs_to :action
  belongs_to :branch
  def to_label
    "Event Log"
  end
  def actions
    self.action
  end
  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
end
