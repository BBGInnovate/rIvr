require 'dropbox'
require 'open-uri'
require 'builder'

class Report < Template
#  def self.generate_xml(branch, client)
#    local_file = self.rss_feed(branch)
#    remote_file = "#{DROPBOX.public_dir}/#{branch.name}/#{File.basename(local_file)}"
#    to = "Public/#{branch.name}/"
#    if !Prompt.file_equal?(remote_file, local_file)
#      begin
#      client.upload local_file, to
#      puts "Uploaded #{local_file} to #{to}"
#      rescue Exception=>e
#        puts "Error generate_xml client.upload(#{local_file}, #{to}) #{e.message}"
#      end
#    else
#      puts "#{to}#{File.basename(local_file)} unchanged"
#    end
#  end
#  def self.rss_feed(branch)
#    options = Configure.conf(branch)
#    feed_limit = options.feed_limit
#    entries = []
#    static_rss = false
#    if options.feed_source == 'dropbox'
#      entries = Entry.where("branch_id='#{branch.id}' AND is_private=0").all(:select => "public_url", :order => "id DESC", :limit => feed_limit )
#    end
#    if entries.size == 0
#      entries = Entry.parse_feed(options.feed_url, feed_limit)
#      static_rss = true
#    end
#    reports = branch.reports
#    file_path = "#{DROPBOX.tmp_dir}/#{branch.name}/bulletin.xml"
#    File.open(file_path, "w") do |file|
#      xml = ::Builder::XmlMarkup.new(:target => file, :indent => 2)
#      xml.instruct! :xml, :version => "1.0"
#      xml.rss :version => "2.0" do
#        xml.channel do
#          xml.forum_type (branch.forum_type || "report")
#          xml.branch branch.name
#          xml.count ''
#          for m in reports
#            xml.item do
#              # <introduction>/bbg/tripoli/report/introduction.wav</introduction>
#              xml.method_missing(m.name, m.dropbox_file)
#            end
#          end
#          for m in entries
#          # these dropbox_file is to copy to ../Uploads in client
#            xml.item do
#              xml.link m.public_url.gsub("https","http")
#            end
#          end
#        end
#      end
#    end
#    return file_path
#  end
end