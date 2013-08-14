require 'ostruct'
class Configure < ActiveRecord::Base
  self.table_name = "options"
  attr_accessor :feed_source
  belongs_to :branch
  
  default_scope where("branch_id is not null")
  
  validates :name, :presence => true, :length => { :maximum => 40 }
  validates :value, :presence => true, :length => { :maximum => 255 }
  validates :description, :length => { :maximum => 255 }
    
  def to_label
    "Configure"
  end
  
  def self.find_me(branch, name)
    o = self.where("branch_id = '#{branch.id}' AND name='#{name}'").order("id DESC").limit(1)
    if o.size>0
      o[0]
    else
      self.new(:branch_id=>branch.id, :name=>name)
    end
  end
  def self.conf(branch)
    os = OpenStruct.new
    res = self.where("branch_id='#{branch.id}'").order("id DESC").all
    os.feed_limit = res.select{|m| m.name=='feed_limit'}[0].value.to_i rescue 3
    os.feed_source = res.select{|m| m.name=='feed_source'}[0].value rescue 'dropbox'
    os.feed_url = res.select{|m| m.name=='feed_url'}[0].value rescue 'http://www.lavoixdelamerique.com/podcast/'
    os
  end

  def self.feed_limit(branch)
    o = self.where("branch_id = '#{branch.id}' AND name='feed_limit'").order("id DESC").limit(1)
    if o.size>0
      o[0].value.to_i
    else
      o = self.new :branch_id=>branch.id, :name=>"feed_limit", :value=>'10'
      o.value
    end
  end
  
  def self.feed_source(branch)
    o = self.where("branch_id = '#{branch.id}' AND name='feed_source'").order("id DESC").limit(1)
    if o.size>0
      o[0].value
    else
      o = self.new :branch_id=>branch.id, :name=>"feed_source", :value=>'dropbox'
      o.value
    end
  end
  def self.feed_url(branch)
    o = self.where("branch_id = '#{branch.id}' AND name='feed_url'").order("id DESC").limit(1)
    if o.size>0
      o[0].value
    else
      o = self.new :branch_id=>branch.id, :name=>"feed_url", :value=>"http://www.lavoixdelamerique.com/podcast/"
      o.value
    end
  end
  
  def feed_limit
    o = Configure.where("branch_id = #{branch.id} AND name='feed_limit'").order("id DESC").limit(1)
    if o.size>0
      o[0].value.to_i
    else
      o = Configure.new :branch_id=>branch.id, :name=>"feed_limit", :value=>'10'
      o.value
    end
  end
  def feed_source
    o = Configure.where("branch_id = #{branch.id} AND name='feed_source'").order("id DESC").limit(1)
    if o.size>0
      o[0].value
    else
      o = Configure.new :branch_id=>branch.id, :name=>"feed_source", :value=>'dropbox'
      o.value
    end
  end
  def feed_url
    o = Configure.where("branch_id = #{branch.id} AND name='feed_url'").order("id DESC").limit(1)
    if o.size>0
      o[0].value
    else
      o = Configure.new :branch_id=>branch.id, :name=>"feed_url", :value=>"http://www.lavoixdelamerique.com/podcast/"
      o.value
    end
  end
end
