class AddPageColumnToArticles < ActiveRecord::Migration
  def change
    add_attachment :articles, :page
  end
end

