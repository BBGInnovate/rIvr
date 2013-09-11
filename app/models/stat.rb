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
  # listened[:total] == total listening in seconds
  # listened[:average] == ave listening in seconds
  # listened[:number_of_calls] == number of calls for listening
  def listened
     hsh = {:total=>0}
     my_events = Event.joins(:branch).where("branches.is_active=1").
     where("events.created_at"=>started..ended).
        where("action_id in (#{Action.begin_listen},#{Action.end_listen})").
        select("session_id, events.branch_id, events.action_id, events.created_at").all

    branches = my_events.uniq {|p| p.branch_id}
    branches.each do |b|
      hsh[b.branch_id] =  {:total=>0, :number_of_calls=>0, :average=>0}
    end
    sessions = my_events.group_by{|e| e.session_id}
    total_seconds = 0
    session_number = sessions.keys.size
    sessions.keys.each do |session_id|
      session_rows=sessions[session_id]
      session_seconds = get_length(session_rows)
      hsh[:total] += session_seconds
      b = session_rows.first
      hsh[b.branch_id][:total] += session_seconds
      hsh[b.branch_id][:number_of_calls] += 1
    end
    branches.each do |b|
      hsh[b.branch_id][:average] = hsh[b.branch_id][:total]/hsh[b.branch_id][:number_of_calls]
    end
    ave = hsh[:total] / sessions.keys.size
    hsh[:number_of_calls]=sessions.keys.size
    hsh[:average]=ave
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
   
  # call_times[branch_id][:total] = total call duration (in seconds) for each branch
  # call_times[branch_id][:rows] = total call number for each branch
  # call_times[branch_id][:average] = average call duration for each branch
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
      hsh[b_id] = {:total=>0, :rows=>0} 
    end 
    subs = events.group_by{|e| e.session_id}
    subs.keys.each do | session_id |
      e = subs[session_id]
      len = e.last.created_at.to_i - e.first.created_at.to_i
      hsh[e.last.branch_id][:total] += len
      total += len
      hsh[e.last.branch_id][:rows] += 1
    end
    tmps.keys.each do |b_id|
      hsh[b_id][:average] = hsh[b_id][:total]/hsh[b_id][:rows]
    end 
    ave_call_time = total / subs.keys.size  
    hsh[:total] = total
    hsh[:rows] = subs.keys.size
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

    def get_length(session_rows)
      listen_started = nil
      listen_ended = nil
      session_listen_time = 0
      session_rows.each do |row|
        if row.action_id == 3 && !listen_started
          listen_started = row.created_at
        elsif row.action_id == 4 && !!listen_started && !listen_ended
          if row.created_at > listen_started
            listen_ended = row.created_at
          end
        end
        if !!listen_ended
          session_listen_time += (listen_ended.to_i - listen_started.to_i)
          listen_ended = nil
          listen_started = nil
        end
      end
      session_listen_time
    end

end