class CreateCountries < ActiveRecord::Migration
  def up
    create_table :countries do |t|
       t.string    :code, :limit => 2
       t.string    :name
    end
    Country.populate
  end
  
  def down
    drop_table :countries
  end
end
