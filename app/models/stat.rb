# for statistics not restricted to one branch
class Stat
  
  # Syntax: Stat.new('2013-08-01','2013-09-1').alerted
  # class << self
    attr_accessor :started, :ended
    
    def initialize(start_date=nil, end_date=nil)
      # start_date, end_date must be format Time.now.to_s(:db)
      # Time.now.beginning_of_month
      if !!start_date
        @started = Time.parse(start_date).beginning_of_day.to_s(:db) 
      else 
        @started = 1.month.ago.to_s(:db) 
      end
      if !!end_date
        @ended = Time.parse(end_date).end_of_day.to_s(:db)
      else
        @ended = Time.now.to_s(:db)
      end
    end
    
    # for active branches
    # alerted[:total] #=> total number of alerts for all
    # alerted[branch_id] #=> number of alerts for the branch
    def alerted
      numbers = AlertedMessage.joins(:branch).where("branches.is_active=1").
      where(:created_at=>started..ended).
      select("branch_id, count(alerted_messages.id) AS total").
      group(:branch_id)
      set_hash(numbers)
    end

    # total listening time for branches
    def listened_length
      len = 0
      Branch.where(:is_active=>true).all.each do |b|
        len += b.events.listened_length(started, ended)
      end
      len
    end
     
  def number_of_calls
    numbers = Event.where(:created_at=>started..ended).
       select("branch_id, count(distinct session_id) as total").
       group(:branch_id)
    set_hash(numbers)
   end
   
  # call_times[branch_id][:seconds] = total call duration for each branch
  # call_times[branch_id][:rows] = total call number for each branch
  # call_times[:total] = total call duration for all branches
  # call_times[:average] = ave call duration
  def call_times
    events = Event.where(:created_at=>started..ended).
         select("session_id, branch_id, created_at")
    hsh = {}
    total = 0
    len  = 0
    tmps = events.group_by{|e| e.branch_id}
    tmps.keys.each do |b_id|
      hsh[b_id] = {:seconds=>0, :rows=>0} 
    end 
    subs = events.group_by{|e| e.session_id}
    subs.keys.each do | session_id |
      e = subs[session_id]
      len = e.last.created_at.to_i - e.first.created_at.to_i
      hsh[e.last.branch_id][:seconds] += len
      total += len
      hsh[e.last.branch_id][:rows] += e.size
    end
    ave_call_time = total / subs.keys.size  
    hsh[:total] = total
    hsh[:average] = ave_call_time
  end
       
    # for active branches
    # in seconds
    # message_length[:total] #=> total message length for all
    # message_length[branch_id] #=> message length for the branch
    def message_length
      numbers=Entry.joins(:branch).where("branches.is_active=1").
      where("entries.created_at"=>started..ended).
      select("branch_id, cast(sum(length) AS SIGNED) AS total").
      group(:branch_id)
      set_hash(numbers)
    end

    # for active branches
    # messages[:total] #=> total message number for all
    # messages[branch_id] #=> message number for the branch
    def messages
      numbers = Entry.joins(:branch).where("branches.is_active=1").
      where("entries.created_at"=>started..ended).
      select("branch_id, count(entries.id) AS total").
      group(:branch_id)
      set_hash(numbers)
    end

    protected

    def set_hash(input_array)
      hsh = {}
      total = 0
      input_array.each do | n |
        hsh[n.branch_id] = n.total
        total += n.total
      end
      hsh[:total] = total
      hsh
    end

  # end
end