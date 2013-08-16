# require 'file_column'
require 'builder'
require 'open-uri'

class Prompt < ActiveRecord::Base
  file_column :sound_file
  belongs_to :branch
#  validates :branch, :presence => true, :length => { :maximum => 50 }
  validates :name, :presence => true, :length => { :maximum => 255 }
  validates :sound_file, :presence => true,:length => { :maximum => 255 }

  def to_label
    "Voice Forum"
  end

  def upload_file=(file_field)
    if !file_field
      self.errors[:sound_file] << "You must select a file"
      return
    end
    file = file_field.original_filename
    self.content_type = file_field.content_type.chomp
    ds = DropboxSession.last
    if !!ds
      client = get_dropbox_session
      to = "/Public/#{self.branch.name}/"
      from = file_field.tempfile
      begin
        self.url = DROPBOX.public_dir + "/#{self.branch.name}/#{file}"
        #        content = client.upload(from, to)
        FileUtils.cp(file_field.tempfile.path, '/tmp/' + file_field.original_filename)
        file_field.tempfile.unlink
        client.upload '/tmp/' + file_field.original_filename, "Public/#{self.branch.name}/"
      rescue Exception => msg
        if msg.kind_of? Dropbox::FileNotFoundError
          self.url = nil
        elsif msg.kind_of? Timeout::Error
          self.url = nil
        end
        logger.debug "Error upload #{from} #{to} : #{msg}"
      end
    end
  end

  # upload voice prompts for all branches to dropbox public/
  def self.rss_feeds
    puts "#{Time.now.utc} Start"
    client = self.new.get_dropbox_session
    Branch.where(:is_active=>true, :name=>'Tripoli').all.each do | branch |
      # branch = en.name.downcase
      dir = "#{DROPBOX.tmp_dir}/#{branch.name}"
      FileUtils.mkdir_p(dir) if !Dir.exists?(dir)
      generate_prompts_xml(branch, client)
      generate_messages_xml(branch, client)
      branch.generate_forum_feed(client)
    end
    puts "#{Time.now.utc} End"
  end

  # must be file pathname, either directory file or web file
  # old_file and new_file must have the same basename
  # old_file is dropbox public file
  # new_file is in temp directory
  def self.file_equal?(old_file, new_file)
    old_file.gsub!("https","http")
    old_file = URI.encode(old_file)
    old_content = ""
    new_content = ""
    if File.extname(old_file) == ".xml"
      begin
        old_content = open(old_file).read
      rescue Exception=>e
        puts "INFO : 1 Prompt file_equal?(#{old_file}) : #{e.message}"
      end
      begin       
        if (new_file =~ /^http/)
          new_content = open(new_file).read
        else
          new_content = File.open(new_file).read
        end
      rescue Exception=>e
        puts "INFO : 2 Prompt file_equal?(#{new_file}) : #{e.message}"
      end
      return (new_content == old_content)
    end
    
    # for audio files, check if the file exists in dropbox
    begin
      url = URI.parse(old_file)
      response = Net::HTTP.new(url.host, url.port).request_head(url.path)
      return (response.code == '200')
    rescue Exception=>e
      puts "INFO : 3 Prompt file_equal?(#{old_file}) : #{e.message}"
      return false
    end
  end
  
  protected

  def self.rss_feed(records, branch, xml_name)
    file_path = "#{DROPBOX.tmp_dir}/#{branch.name}/#{xml_name}.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
        xml.channel do
          xml.forum_type (branch.forum_type || "report")
          xml.branch branch.name
          xml.count records.size
          for m in records
            xml.item do
              if (xml_name == "prompts")
                xml.method_missing(m.name, m.url)
              elsif (xml_name == "messages")
                xml.link m.public_url.gsub("https","http")
              end
            end
          end
        end
      end
    end
    return file_path
  end

  def self.generate_prompts_xml(branch, client)
    name = branch.name
    # In Branch, Prompt tables Branch is not downcased
    prompts = Prompt.where("branch_id='#{branch.id}' AND is_active=1").all
    local_file = self.rss_feed(prompts, branch, "prompts")
    remote_file = "#{DROPBOX.public_dir}/#{name}/#{File.basename(local_file)}"
    to = "Public/#{name}/"
    if !file_equal?(remote_file, local_file)
      client.upload local_file, to
      puts "Uploaded #{local_file} to #{to}"
    else
      puts "#{to}#{File.basename(local_file)} unchanged"
    end
  end

  def self.generate_messages_xml(branch, client)
    name = branch.name
    options = Configure.conf(branch)
    feed_limit = options.feed_limit
    entries = []
    static_rss = false
    if options.feed_source == 'dropbox'
      entries = Entry.where("branch_id='#{branch.id}' AND is_private=0").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )
    end
    if entries.size == 0
      entries = Entry.parse_feed(options.feed_url, feed_limit)
      static_rss = true
    end
    if entries.size > 0
      local_file = self.rss_feed(entries, branch, "messages")
      remote_file = "#{DROPBOX.public_dir}/#{name}/#{File.basename(local_file)}"
      to = "Public/#{name}/"
      if !file_equal?(remote_file, local_file)
        puts "#{Time.now.utc} Uploading #{local_file} to #{to}"
        client.upload local_file, to
        puts "#{Time.now.utc} Uploaded #{local_file} to #{to}"
        if static_rss
          # upload static_rss type public messages to dropbox
          entries.each do |entry|
            # this entry is not Entry type!
            Entry.upload_static_message(client, entry, branch)
          end
        end
      else
        puts "#{to}#{File.basename(local_file)} unchanged"
      end
    end
  end

  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/,'')
  end

end
