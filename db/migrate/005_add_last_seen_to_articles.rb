class AddLastSeenToArticles < ActiveRecord::Migration
  def change
    change_table :articles, force: true do |t|
      t.datetime :last_seen
    end
  end
end

