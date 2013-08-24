class AlterTemplates < ActiveRecord::Migration
  def up
    add_column :templates, :identifier, :string, :limit=>40
    add_index :templates, :identifier
  end

  def down
    drop_index :templates, :identifier
    remove_column :templates, :identifier
  end
end
