class Schema < ActiveRecord::Migration
  def change
    create_table :articles, force: true do |t|
      t.string :title
      t.boolean :deleted, default: false
      t.boolean :on_list, default: true
    end
  end
end
