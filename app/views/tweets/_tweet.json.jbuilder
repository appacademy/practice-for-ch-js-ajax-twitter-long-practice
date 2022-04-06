json.extract! tweet, :body, :created_at
json.author tweet.author, :id, :username

if tweet.mentioned_user_id.present?
  json.mentioned_user tweet.mentioned_user, :id, :username 
end