class CreateBranches < ActiveRecord::Migration
  def up
      create_table "branches" do |t|
        t.string :name, :limit => 50
        t.integer :country_id
        t.string :description
        t.boolean :is_active, :default=>false
        t.timestamps
      end
      ops = Option.select("distinct branch")
      ops.each do |name| 
        Branch.create :name=>name.branch, :is_active=>true
      end
      add_index :branches, :name, :unique => true
    end
  
    def down
      remove_index :branches, :name
      drop_table "branches"
    end
end
