class Action< ActiveRecord::Base
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
end