class AddLatLonBranches < ActiveRecord::Migration
  def up
    add_column :branches, :latitude, :float #you can change the name, see wiki
    add_column :branches, :longitude, :float #you can change the name, see wiki
    add_column :branches, :gmaps, :boolean, :default=>true #not mandatory, see wiki
  end

  def down
    remove_column :branches, :latitude
    remove_column :branches, :longitude
    remove_column :branches, :gmaps
  end
end
