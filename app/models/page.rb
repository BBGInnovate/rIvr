class Page< ActiveRecord::Base
  def self.constant_iter(&block)
    Page.all.each do |c|
      yield c.name, c.id
    end
  end

  self.constant_iter do |name, id|
    begin
      class_eval "def self.#{name}; #{id}; end"
    rescue
      logger.error "#{name} - #{id} cannot converted"
    end
  end
  
  def self.truncate
      connection.execute "truncate table #{table_name}"
  end
    
end