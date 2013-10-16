class SortedEntry< ActiveRecord::Base
   belongs_to :branch
   belongs_to :entry
   def self.clean(branch_id, forum_session_id=nil)
     if forum_session_id
       destroy_all :branch_id=>branch_id,
          :forum_session_id=>forum_session_id
     else
       destroy_all :branch_id=>branch_id
     end
   end

   def self.get(branch_id, forum_session_id)
      where(:branch_id=>branch_id, :forum_session_id=>forum_session_id).where("rank>0").order("rank")
   end
   
   def self.update(all_ids, sorted_ids)
      sorted_ids = [] if !sorted_ids
      unsorted_ids = all_ids - sorted_ids
      ranks = {}
      sorted_ids.each do |id|
        item = Entry.find_by_id id
        ranks[item.branch_id] = 0
      end
      sorted_ids.each_with_index do |id, i|
        e = Entry.find_by_id id
        ranks[e.branch_id] += 1
        s = SortedEntry.find_by_entry_id id
        if s 
          s.update_attribute :rank, ranks[e.branch_id]
        else
          SortedEntry.create :branch_id=>e.branch_id,
            :entry_id=>e.id,
            :forum_session_id=>e.forum_session_id,
            :dropbox_file=>e.dropbox_file,
            :rank=>ranks[e.branch_id],
            :created_at =>e.created_at
        end
     end 
     unsorted_ids.each do |id|
       s = SortedEntry.find_by_entry_id id
       if s 
          s.update_attribute :rank,0
       end
     end
   end
   
   def is_private
     false
   end
   def is_active
     self.entry.is_active
   end
   def dropbox_file_exists?
     self.entry.dropbox_file_exists?
   end
   def soundkloud
     self.entry.soundkloud
   end
   def checked?
     rank > 0
   end
end