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
      where(:branch_id=>branch_id, :forum_session_id=>forum_session_id)
   end
   
   def self.insert(entry_ids)
      entry_ids.each_with_index do |id, i|
        e = Entry.find_by_id id
        if e
          clean(e.branch.id, e.forum_session_id) if i==0
          SortedEntry.create :branch_id=>e.branch_id,
          :entry_id=>e.id,
          :forum_session_id=>e.forum_session_id,
          :dropbox_file=>e.dropbox_file,
          :rank=>i,
          :created_at =>e.created_at
        end
     end 
   end
   
   def dropbox_file_exists?
     self.entry.dropbox_file_exists?
   end
   def checked?
     true
   end
end