xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
#    xml.title "Public Recording"
#    xml.description "Public Recording"
#    xml.link feed_api_index_url
    xml.count @entries.size
    for entry in @entries
      xml.item do
#        xml.title entry.dropbox_file
#        xml.pubDate entry.created_at.to_s(:rfc822)
        xml.link entry.public_url.gsub("https","http")
#        xml.guid entry.public_url
      end
    end
  end
end