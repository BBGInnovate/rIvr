xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
#    xml.title "Public Recording"
#    xml.description "Public Recording"
#    xml.link feed_api_index_url
    xml.count @messages.size
    for m in @messages
      xml.item do
#        xml.title entry.dropbox_file
        xml.method_missing(m.name, m.url)
#        xml.guid entry.public_url
      end
    end
  end
end
