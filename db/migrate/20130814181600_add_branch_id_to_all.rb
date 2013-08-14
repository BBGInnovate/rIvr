class AddBranchIdToAll < ActiveRecord::Migration
  def change
    [:entries, :events, :healthes, :options, :prompts].each do |t|
      add_column t, :branch_id, :integer
      rename_column t, :branch, :branch_name
    end
    
    [Entry, Event, Health, Option, Prompt].each do |t|
      t.reset_column_information
      t.all.each do | record |
          b = Branch.find_by_name record.branch_name
          if !!b
            record.branch_id = b.id
            record.save
          end
      end
    end
  end
end
