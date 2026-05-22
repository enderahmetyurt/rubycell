class CreateArticles < ActiveRecord::Migration[8.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :url
      t.string :source
      t.string :source_url
      t.datetime :published_at
      t.text :summary_tr
      t.text :summary_en
      t.integer :score
      t.boolean :ai_filtered, default: false, null: false
      t.boolean :relevant, default: true, null: false

      t.timestamps
    end
    add_index :articles, :url, unique: true
  end
end
