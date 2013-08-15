require 'dropbox'
require 'open-uri'
require 'builder'

class Report < Template
  def self.rss_feeds
      puts "#{Time.now.utc} Start"
      client = self.new.get_dropbox_session
      Branch.where(:is_active=>true).all.each do | branch |
        dir = "#{DROPBOX.tmp_dir}/#{branch.name}"
        FileUtils.mkdir_p(dir) if !Dir.exists?(dir)
        generate_report_xml(branch, client)
      end
      puts "#{Time.now.utc} End"
  end
    
  def self.generate_report_xml(branch, client)
    local_file = self.rss_feed(branch)
    remote_file = "#{DROPBOX.public_dir}/#{branch.name}/#{File.basename(local_file)}"
    to = "Public/#{branch.name}/"
    if !Prompt.file_equal?(remote_file, local_file)
      client.upload local_file, to
      puts "Uploaded #{local_file} to #{to}"
    else
      puts "#{to}#{File.basename(local_file)} unchanged"
    end
  end
  def self.rss_feed(branch)
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
    records = self.where(:branch_id => branch.id, :is_active=>true)
    file_path = "#{DROPBOX.tmp_dir}/#{branch.name}/report.xml"
    File.open(file_path, "w") do |file|
      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
      xml.instruct! :xml, :version => "1.0"
      xml.rss :version => "2.0" do
      xml.channel do
        xml.forum_type (branch.forum_type || "report")
        xml.branch branch.name
        xml.count ''
        for m in records
          xml.item do
            xml.method_missing(m.name, m.dropbpx_file)
          end
        end
        for m in entries
          # these dropbox_file is to copy to ../Uploads in client
          xml.item do
            xml.link m.public_url.gsub("https","http")
          end
        end
      end
    end
    end
  end
end