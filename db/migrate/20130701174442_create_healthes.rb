class CreateHealthes < ActiveRecord::Migration
  def up
        create_table "healthes" do |t|
          t.string :branch, :limit => 50
          t.integer :event_id
          t.datetime :last_event
          t.string :event
          t.integer :no_activity, :default=> 6*3600
          t.string :deliver_method, :limit=>20
          t.string :email, :limit => 50
          t.string :cell_phone, :limit => 20
          t.string :phone_carrier, :limit => 20
          t.boolean :send_alarm, :default=>false
          t.timestamps
        end
        add_index :healthes, :branch, :unique => true
        Branch.all.each do |b|
          Health.create :branch=>b.name
        end
      end
    
      def down
        remove_index :healthes, :branch
        drop_table "healthes"
      end
end
