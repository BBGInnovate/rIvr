class Branch< ActiveRecord::Base
  self.table_name = "branches"
  belongs_to :country, :foreign_key=>"country_id"
  def self.constant_iter(&block)
      Action.all.each do |c|
        yield c.name, c.id
      end
    end
  
    self.constant_iter do |name, id|
      begin
        class_eval "def self.#{name.gsub(' ','_')}; #{id}; end"
      rescue
        logger.error "#{name} - #{id} cannot converted"
      end
    end
  def self.find_me(attr)
    self.first :conditions=>["id=? or name=?", attr, attr]
  end
end