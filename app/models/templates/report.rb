require 'dropbox'
require 'open-uri'
require 'builder'

class Report < Template

   def upload_to_dropbox(file)
    to = self.branch.entry_files_folder(self.voting_session.name)
    remote_dir = DROPBOX.home+to
    remote_file = remote_dir + "/" + file.original_filename
    entry = Entry.create :branch_id=>self.branch_id, 
            :forum_type=>'report',
            :dropbox_dir => to,
            :dropbox_file=>file.original_filename,
            :mime_type=>file.content_type,
            :forum_session_id=>self.voting_session_id,
            :is_private=>false,
            :is_active=>false
       

    # not use local dropbox     
    if 1==0 && (Dir.exists? DROPBOX.home)
      # dropbox client is installed
      # have to be sure the dropbox client is running
      if !Dir.exists?(remote_dir)
         FileUtils.mkdir_p remote_dir
      end
      FileUtils.copy file.tempfile.path, remote_file
      logger.info "Copied #{file.tempfile.path} to #{remote_file}"
    else    
      client = self.get_dropbox_session
      if !!client
        begin
          client.mkdir to
        rescue Dropbox::FileExistsError
          # it is ok
        rescue 
          logger.warn "Error: upload_to_dropbox : #{$!}"
          entry.destroy
          return false
        end
        begin
          re = client.upload(file.tempfile, to, :as=>file.original_filename)
          logger.warn "INFO: Dropbox uploaded: #{file.original_filename}"
        rescue Exception=>ex
          logger.warn "Error #{ex.message}"
          entry.destroy
          return false
        end
      end
    end
    add_sorted_entry(entry)
    return true
  end

  def add_sorted_entry(item)
    ss = SortedEntry.where(:branch_id=>self.branch_id, :forum_session_id=>item.forum_session_id).
       order("created_at ASC")
    # delete files to make room for new file  
    feed_limit = self.branch.feed_limit
    if ss.size > feed_limit
      ss[0..(ss.size-feed_limit-1)].each do |s| 
        s.destroy
      end
    end
    SortedEntry.create :branch_id=>self.branch_id,
            :entry_id=>item.id,
            :rank=>1,
            :dropbox_file=>item.dropbox_file,
            :forum_session_id=>item.forum_session_id,
            :created_at =>item.created_at
    self.dropbox_file = "#{item.dropbox_dir}/#{item.dropbox_file}"
    self.content_type = item.mime_type
    self.save
   # generate_forum_feed_xml

  end

end