class RenameHealthes < ActiveRecord::Migration
  def up
    rename_table :healthes, :healths
  end

  def down
    rename_table :healths, :healthes
  end
end
