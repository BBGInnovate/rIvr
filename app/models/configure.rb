require 'ostruct'
class Configure < ActiveRecord::Base
  self.table_name = "options"
  attr_accessor :feed_source
  belongs_to :branch
  
  default_scope where("branch_id is not null")
  
  validates :name, :presence => true, :length => { :maximum => 40 }
  validates :value, :presence => true, :length => { :maximum => 255 }
  validates :description, :length => { :maximum => 255 }
  validates :feed_source, :presence => true, :length => {:minimum=>2, :maximum => 40 }
  validates_inclusion_of :branch_id, :in => 1..9999999999
  
  def to_label
    "Configure"
  end
  
  def self.find_me(branch, name)
    begin
      if branch.kind_of? String
        o = self.where("branch_id = #{branch} AND name='#{name}'").order("id DESC").limit(1)
      else
        o = self.where("branch_id = '#{branch.id}' AND name='#{name}'").order("id DESC").limit(1)
      end
      if o.size>0
        o[0]
      else
        self.new(:branch_id=>(branch.kind_of?(String) ? branch.to_i : branch.id), :name=>name)
      end
    rescue
      nil
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
    begin
      o = Configure.where("branch_id = #{branch.id} AND name='feed_limit'").order("id DESC").limit(1)
      if o.size>0
        o[0].value.to_i
      else
        o = Configure.new :branch_id=>branch.id, :name=>"feed_limit", :value=>'10'
        o.value
      end
    rescue
      ""
    end
  end
  def feed_source
    begin
      o = Configure.where("branch_id = #{branch.id} AND name='feed_source'").order("id DESC").limit(1)
      if o.size>0
        o[0].value
      else
        o = Configure.new :branch_id=>branch.id, :name=>"feed_source", :value=>'dropbox'
        o.value
      end
    rescue 
      ""
    end
  end
  def feed_url
    begin
      o = Configure.where("branch_id = #{branch.id} AND name='feed_url'").order("id DESC").limit(1)
      if o.size>0
        o[0].value
      else
        o = Configure.new :branch_id=>branch.id, :name=>"feed_url", :value=>"http://www.lavoixdelamerique.com/podcast/"
        o.value
      end
    rescue
      ""
    end
  end
end
