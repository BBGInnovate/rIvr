class CreatePrompts < ActiveRecord::Migration
  def up
        create_table "prompts" do |t|
          t.column :branch, :string, :limit => 50
          t.column :name,                      :string
          t.column :sound_file,                :string
          t.column :content_type,              :string
          t.column :url,                       :string
          t.column :language,                  :string
          t.column :description,               :string
          t.column :is_active,                 :boolean, :default=>1
          t.timestamps
        end
        add_index :prompts, :branch
      end
    
      def down
        remove_index :prompts, :branch
        drop_table "prompts"
      end
end
