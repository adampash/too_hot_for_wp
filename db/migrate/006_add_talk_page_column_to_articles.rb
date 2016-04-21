class AddTalkPageColumnToArticles < ActiveRecord::Migration
  def change
    add_attachment :articles, :talk_page
  end
end


