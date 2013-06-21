require 'ostruct'
class Option < ActiveRecord::Base
  def to_label
    "Option"
  end
  
  def public_url
    if self.name == 'recording_url'
      self.value
    else
      nil
    end
  end
#  def self.conf(branch)
#    os = OpenStruct.new
#    res = self.where("branch='#{branch}'").order("id DESC").all
#    os.feed_limit = res.select{|m| m.name=='feed_limit'}[0].value.to_i rescue 10
#    os.feed_source = res.select{|m| m.name=='feed_source'}[0].value rescue 'dropbox'
#    os.feed_url = res.select{|m| m.name=='feed_url'}[0].value rescue 'http://www.lavoixdelamerique.com/podcast/'
#    os
#  end

end
