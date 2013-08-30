class ChangeBranchNameIndex < ActiveRecord::Migration
  def up
    begin
      remove_index :entries, [:branch, :dropbox_file]
    rescue
      puts "Error #{$!}"
    end
    begin
      remove_index :events, :caller_id
    rescue
      puts "Error #{$!}"
    end
    begin
      remove_index :healths, [:branch, :event_id]
    rescue
      puts "Error #{$!}"
    end
    begin
      remove_index :options, :branch
    rescue
      puts "Error #{$!}"
    end
    begin
      remove_index :prompts, :branch
    rescue
      puts "Error #{$!}"
    end

    add_index :entries, [:branch_id, :dropbox_file, :created_at] rescue ""
    add_index :events, [:branch_id, :action_id, :session_id, :created_at] rescue ""
    add_index :healths, [:branch_id, :event_id] rescue ""
    add_index :options, :branch_id rescue ""
    add_index :prompts, :branch_id rescue ""

  end

  def down
#    remove_index :entries, [:branch_id, :dropbox_file, :created_at]
    remove_index :events, [:branch_id, :action_id, :created_at]
  end
end
