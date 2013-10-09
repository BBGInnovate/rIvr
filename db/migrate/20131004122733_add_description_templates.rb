class AddDescriptionTemplates < ActiveRecord::Migration
  def up
    add_column :templates, :description, :string
    Template.all.each do |t|
      if t.temp_type == 'Vote'
        t.description='participate'
        t.save
      end
    end
  end

  def down
    remove_column :templates, :description
  end
end
