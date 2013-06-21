class CreateActions < ActiveRecord::Migration
  def up
    create_table "actions" do |t|
      t.string :branch, :limit => 50
      t.column :name, :string, :limit => 50
      t.timestamps
    end
    acts = ['hangup','pressed 9','begin listen', 'end listen',
      'begin recording','end recording','submit recording',
      'cancel recording', 'save recording', 'cannot save recording',
      'error','skip message']
    acts.each do |name| 
      Action.create :name=>name
    end
  end

  def down
    drop_table "actions"
  end
end
