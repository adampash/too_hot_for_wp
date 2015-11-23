class AddArchivedToArticles < ActiveRecord::Migration
  def change
    change_table :articles, force: true do |t|
      t.boolean :archived, default: :false
    end
  end
end

