class Health< ActiveRecord::Base
  self.table_name = "healthes"
  
  def self.truncate
      connection.execute "truncate table #{table_name}"
  end
end