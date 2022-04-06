class Tweet < ApplicationRecord
  validates :body, presence: true, length: { maximum: 280 }

  belongs_to :author, 
    foreign_key: :author_id,
    class_name: :User
  belongs_to :mentioned_user,
    foreign_key: :mentioned_user_id,
    class_name: :User,
    optional: true
end
