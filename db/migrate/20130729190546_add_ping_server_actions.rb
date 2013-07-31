class AddPingServerActions < ActiveRecord::Migration
  def up
    a = Action.find_by_name "ping server"
    if !a
      Action.create :name=>"ping server"
    end
    begin
      remove_index :healthes, :branch
    rescue
    end
    add_index :healthes, [:branch, :event_id]
  end

  def down
    remove_index :healthes, [:branch, :event_id]
  end
end
