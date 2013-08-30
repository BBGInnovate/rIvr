class AlertedMessage< ActiveRecord::Base
  belongs_to :branch
  
  # return AlertedMessage object array with attr branch_id, total
  def self.numbers(start_date=nil, end_date=nil)
    # start_date, end_date must be format Time.now.to_s(:db)
    start_date = 1.month.ago.to_s(:db) if !start_date
    end_date = Time.now.to_s(:db) if !end_date
    num = where(:created_at=>start_date..end_date).
       group(:branch_id).
       select("branch_id, count(id) AS total")
  end

  def self.number_by_branch(branch_id, start_date=nil, end_date=nil)
    # start_date, end_date must be format Time.now.to_s(:db)
    arr = self.numbers(start_date, end_date)
    o = arr.select{|a| a.branch_id == branch_id}.first
    !!o ? o.total : 0
  end

end