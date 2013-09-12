class AddIsActiveEntries < ActiveRecord::Migration
  def up
    add_column :entries, :is_active, :boolean, :default=>true
  end

  def down
    remove_column :entries, :is_active
  end
end
