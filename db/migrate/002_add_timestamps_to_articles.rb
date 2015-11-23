class AddTimestampsToArticles < ActiveRecord::Migration
  def change
    change_table :articles, force: true do |t|
      t.datetime :deleted_at
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
