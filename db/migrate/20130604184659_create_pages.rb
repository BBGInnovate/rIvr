class CreatePages < ActiveRecord::Migration
  def up
    create_table "pages" do |t|
      t.column :name, :string, :limit => 50
      t.timestamps 
    end
    ['listenMessages','recordMessageUI', 'recordMessage','cleanUp',
      'home','errorLog'].each do |name| 
      Page.create :name=>name
    end
  end

  def down
    drop_table "pages"
  end
end
