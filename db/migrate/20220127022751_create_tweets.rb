class CreateTweets < ActiveRecord::Migration[7.0]
  def change
    create_table :tweets do |t|
      t.text :body, null: false
      t.bigint :author_id, null: false, index: true
      t.bigint :mentioned_user_id, index: true

      t.timestamps
    end
  end
end
