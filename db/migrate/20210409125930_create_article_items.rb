class CreateArticleItems < ActiveRecord::Migration[6.0]
  def change
    create_table :article_items do |t|
      t.string :guid
      t.integer :source

      t.timestamps
    end
  end
end
