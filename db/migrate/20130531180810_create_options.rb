class CreateOptions < ActiveRecord::Migration
  def up
    create_table "options" do |t|
      t.column :branch,                    :string, :limit => 50
      t.column :name,                      :string, :limit => 40
      t.column :value,                     :string
      t.column :description,               :string
      t.timestamps
    end
    add_index :options, :branch
  end

  def down
    remove_index :options, :branch
    drop_table "options"
  end
end
