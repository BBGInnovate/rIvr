class Event < ActiveRecord::Base
  belongs_to :action
  belongs_to :branch
  
  after_save :update_health
  
  def to_label
    "Event Log"
  end
  def actions
    self.action
  end
  
  def update_health
    h = self.branch.health
    if h 
      h.last_event = self.created_at
      h.save
    end
  end
  
  def self.truncate
    connection.execute "truncate table #{table_name}"
  end
end
