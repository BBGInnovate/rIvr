# for statistics not restricted to one branch
class Stat
  
  # Syntax: Stat.new('2013-08-01','2013-09-1').alerted
  # class << self
    attr_accessor :started, :ended, :branches, :branch_ids, :countries
    
    def initialize(start_date=nil, end_date=nil, mybranches=[])
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
      if mybranches.size>0
        @branches = mybranches
      else
        @branches = Branch.where("branches.is_active=1").all
      end
      @branch_ids = @branches.map{|b| b.id}
      @countries = @branches.map{|b| b.country }.uniq
    end
    
  # number of branches no activities in started..ended
  def no_activity
    activities = Health.
      where(["healths.branch_id in (?)", branch_ids]).
      where("TIMESTAMPDIFF(HOUR,last_event, NOW()) < healths.no_activity").
      select("branch_id").
      group(:branch_id)

    no_activities = branch_ids - activities.map{|a| a.branch_id} 
      {:unique => no_activities.size}
   end
      
    # for active branches
    # alerted[:total] #=> total number of alerts for all
    # alerted[branch_id] #=> number of alerts for the branch
    # hsh[:unique] number of branches having alerts.
    def alerted
      numbers = AlertedMessage.
        where(["alerted_messages.branch_id in (?)", branch_ids]).
        where(:created_at=>started..ended).
        select("branch_id, count(alerted_messages.id) AS total").
        group(:branch_id)
      hsh = set_hash(numbers)
    end
  # listened[:total] == total listening in seconds
  # listened[:average] == ave listening in seconds
  # listened[:number_of_calls] == number of calls for listening
  def listened
    hsh = {:total=>0}
    my_events = Event.includes(:branch).where(["events.branch_id in (?)", branch_ids])
    my_events = my_events.where("events.created_at"=>started..ended).
        where("action_id in (#{Action.begin_listen},#{Action.end_listen})").
        select("session_id, events.branch_id, events.action_id, events.created_at").all

    @countries.each do |c|
      hsh[c.name] = {:total=>0, :number_of_calls=>0, :average=>0}
    end
    branches.each do |b|
      hsh[b.id] =  {:total=>0, :number_of_calls=>0, :average=>0}
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
      hsh[country_name(b.branch.country_id)][:total] += session_seconds
      hsh[country_name(b.branch.country_id)][:number_of_calls] += 1
    end
    branches.each do |b|
      if hsh[b.id][:number_of_calls]>0
        hsh[b.id][:average] = hsh[b.id][:total]/hsh[b.id][:number_of_calls]
      else
        hsh[b.id][:average] = 0
      end
    end
    ave = sessions.keys.size>0 ? (hsh[:total] / sessions.keys.size) : 0
    hsh[:number_of_calls]=sessions.keys.size
    hsh[:average]=ave
    @countries.each do |c|
      if hsh[c.name][:total] > 0
         hsh[c.name][:average] = 
           hsh[c.name][:total] / hsh[c.name][:number_of_calls]
      end
    end
    hsh
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
       where(["events.branch_id in (?)",branch_ids]).
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
    events = Event.includes(:branch).where(:created_at=>started..ended).
         where(["events.branch_id in (?)",branch_ids]).
         select("session_id, branch_id, created_at")
    hsh = {}
    total = 0
    len  = 0
    @countries.each do |c|
      hsh[c.name] = {:total=>0, :rows=>0, :average=>0} 
    end
    branches.each do |b|
      hsh[b.id] = {:total=>0, :rows=>0, :average=>0} 
    end 
    subs = events.group_by{|e| e.session_id}
    subs.keys.each do | session_id |
      e = subs[session_id]
      len = e.last.created_at.to_i - e.first.created_at.to_i
      hsh[e.last.branch_id][:total] += len
      hsh[country_name(e.last.branch.country_id)][:total] += len
      total += len
      hsh[e.last.branch_id][:rows] += 1
      hsh[country_name(e.last.branch.country_id)][:rows] += 1
    end
    branches.each do |b|
      if hsh[b.id][:rows] > 0
        hsh[b.id][:average] = hsh[b.id][:total]/hsh[b.id][:rows]
      end
    end 
    @countries.each do |c|
      if hsh[c.name][:total]>0
        hsh[c.name][:average] = 
          hsh[c.name][:total] / hsh[c.name][:rows]
      end
    end
    ave_call_time = subs.keys.size>0 ? (total / subs.keys.size) : 0
    hsh[:total] = total
    hsh[:rows] = subs.keys.size
    hsh[:average] = ave_call_time
    hsh
  end
       
    # for active branches
    # in seconds
    # message_length[:total] #=> total message length for all
    # message_length[branch_id] #=> message length for the branch
    def message_length
      numbers=Entry.where(["branches.id in (?)",branch_ids]).
      where("entries.created_at"=>started..ended).
      select("branch_id, cast(sum(length) AS SIGNED) AS total").
      group(:branch_id)
      set_hash(numbers)
    end

    # for active branches
    # messages[:total] #=> total message number for all
    # messages[branch_id] #=> message number for the branch
    def messages
    #  numbers = Entry.joins(:branch).where("branches.is_active=1").
      numbers = Entry.includes(:branch).where(["entries.branch_id in (?) ", branch_ids]).
      where("entries.created_at"=>started..ended).
      select("branch_id, count(entries.id) AS total").
      group(:branch_id)
      hsh = set_hash(numbers)
      hsh
    end
    # not moderated messages
    def new_messages
      numbers = Entry.includes(:branch).where(["entries.branch_id in (?) ", branch_ids]).
      where("entries.created_at"=>started..ended).
      where("entries.is_private"=>true).
      where("entries.created_at != entries.updated_at").
      select("branch_id, count(entries.id) AS total").
      group(:branch_id)
      hsh = set_hash(numbers)
      hsh
    end
    
    protected

    def set_hash(input_array)
      hsh = {:unique=>0}
      total = 0
      @countries.each do |c|
        hsh[c.name] = {:total=>0, :rows=>0, :average=>0, :branches=>[]}
      end
      branches.each do |b|
        hsh[b.id] = {:total=>0}
      end
      unique_branches = []
      input_array.each do | n |
        if !unique_branches.include?(n.branch_id)
          unique_branches << n.branch_id
        end
        hsh[country_name(n.branch.country_id)][:branches] << n.branch.name
        hsh[n.branch_id][:total] = n.total
        hsh[country_name(n.branch.country_id)][:total] += n.total
        total += n.total
        hsh[country_name(n.branch.country_id)][:rows] += 1
      end
      hsh[:unique] = unique_branches.size
      hsh[:total] = total
      @countries.each do |c|
        hsh[c.name][:branches].uniq!
        if hsh[c.name][:total] > 0
          hsh[c.name][:average] = 
            hsh[c.name][:total] / hsh[c.name][:rows]
        end
      end
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

    def country_name(id)
      countries.detect{|c| c.id==id}.name
    end
end
