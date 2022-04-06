class CreateMentions < ActiveRecord::Migration[7.0]
  def change
    create_table :mentions do |t|
      t.bigint :tweet_id, null: false, index: true
      t.bigint :user_id, null: false, index: true

      t.timestamps
    end
  end
end
