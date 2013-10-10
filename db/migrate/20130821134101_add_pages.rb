class AddPages < ActiveRecord::Migration
  def up
    ['listenMessages','recordMessageUI', 'recordMessage','cleanUp','home','errorLog',   
     'testing','listenReport','listenBulletin','recordBulletinUI','recordBulletin','bulletin',
     'listenVoteResults','vote','recordCommentUI', 'castVote', 'recordComment', 'listenComment'].each do |name|
      p = Page.find_by_name name
      if !p
        Page.create :name=>name
      end
    end
  end

  def down
  end
end
