require 'open-uri'
require 'nokogiri'
class Country< ActiveRecord::Base
   def self.populate
     url = "https://raw.github.com/umpirsky/country-list/master/country/cldr/en/country.xml"
     doc = Nokogiri::XML(open(url))
     @links = doc.xpath('//countries/country').each do |i|
        self.create :code=> i.xpath('iso').text, :name=>i.xpath('name').text
     end
   end
   
   def self.language
     url="http://webdesign.about.com/od/localization/l/bllanguagecodes.htm"
     doc = Nokogiri::HTML(open(url))
     langs = doc.css('#languages tr td')
     (0..(langs.size-1)).step(2).each do |i|
        puts langs[i].text + " -- " + langs[i+1].text
     end
   end
end