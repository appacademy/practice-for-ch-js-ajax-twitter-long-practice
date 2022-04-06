class CreateFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :follows do |t|
      t.bigint :follower_id, null: false, index: true
      t.bigint :following_id, null: false, index: true

      t.timestamps
    end

    add_index :follows, [:follower_id, :following_id], unique: true
  end
end
