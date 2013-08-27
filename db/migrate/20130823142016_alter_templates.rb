class AlterTemplates < ActiveRecord::Migration
  def up
    add_column :templates, :voting_session_id, :integer
  end

  def down
    remove_index :templates, :voting_session_id
    remove_column :templates, :voting_session_id
  end
end
