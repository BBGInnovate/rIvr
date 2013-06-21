class AlterEntriesAddOption < ActiveRecord::Migration
  def up
    add_column :entries, :option, :string, :limit=>20
    # listening | recording
  end

  def down
    remove_column :entries, :option
  end
end
