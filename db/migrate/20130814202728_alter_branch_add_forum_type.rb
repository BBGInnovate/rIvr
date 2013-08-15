class AlterBranchAddForumType < ActiveRecord::Migration
  def up
    add_column :branches, :forum_type, :string, :limit=>30
  end

  def down
    remove_column :branches, :forum_type
  end
end
