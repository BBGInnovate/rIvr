class AlertedMessage< ActiveRecord::Base
  belongs_to :branch
  
  # for active branches
  # alerted[:total] #=> total number of alerts for all
  # alerted[branch_id] #=> number of alerts for the branch
  def self.alerted(start_date=nil, end_date=nil)
    # start_date, end_date must be format Time.now.to_s(:db)
    Stat.new(start_date, end_date).alerted
  end

  def self.alerted_by_branch(branch_id, start_date=nil, end_date=nil)
    arr = self.alerted(start_date, end_date)
    arr[branch_id]
  end

end