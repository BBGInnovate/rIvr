class CreateTemplates < ActiveRecord::Migration
  def up
    create_table :templates do |t|
      t.string  :name, :limit=>30, :null => false
      t.string  :dropbox_file
      t.string  :content_type, :limit=>30
      t.boolean :is_active, :default => false
      t.string  :temp_type, :limit=>40
      t.integer  :branch_id
      t.timestamps
    end
    add_index :templates, :branch_id, :unique => false
    # add_attachment :templates, :sound
  end

  def down
    # remove_attachment :templates, :sound
    remove_index :templates, :branch_id
    drop_table :templates
  end
end
