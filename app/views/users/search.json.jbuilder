json.array! @users do |user|
  json.extract! user, :id, :username
  json.following current_user.follows?(user)
end