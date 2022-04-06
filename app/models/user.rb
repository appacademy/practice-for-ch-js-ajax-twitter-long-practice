class User < ApplicationRecord
  attr_reader :password

  validates :username, :password_digest, :session_token, presence: true
  validates :username, uniqueness: true
  validates :password, length: { minimum: 6, allow_nil: true }

  # I'm the one users are *following*, so they are my *followers*
  has_many :in_follows,
    foreign_key: :following_id,
    class_name: :Follow
  has_many :followers,
    through: :in_follows,
    source: :follower

  # I'm the *follower*, so these are the users I'm *following*
  has_many :out_follows,
    foreign_key: :follower_id,
    class_name: :Follow
  has_many :following,
    through: :out_follows,
    source: :following

  has_many :tweets, 
    foreign_key: :author_id,
    dependent: :destroy
  has_many :followed_tweets,
    through: :following,
    source: :tweets

  after_initialize :ensure_session_token

  def self.find_by_credentials(username, password)
    user = User.find_by(username: username)
    user && user.is_password?(password) ? user : nil
  end

  def self.generate_session_token
    loop do
      token = SecureRandom.base64
      break token unless User.exists?(session_token: token)
    end
  end

  def password=(password)
    @password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def is_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def reset_session_token!
    self.update!(session_token: User.generate_session_token)
    self.session_token
  end

  def page_of_tweets(type:, offset: 0, limit: nil)
    tweet_source = 
      case type
      when "feed", :feed then followed_tweets
      when "profile", :profile then tweets
      else 
        raise ArgumentError.new("Invalid type '#{type}' provided to User#page_of_tweets")
      end
    
    tweet_source
      .limit(limit || 10)
      .offset(offset)
      .order(created_at: :desc)
      .includes(:author, :mentioned_user)
  end

  def follows?(user)
    following.any? { |u| u == user }
  end

  private

  def ensure_session_token
    self.session_token ||= User.generate_session_token
  end
end