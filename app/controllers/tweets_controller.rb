class TweetsController < ApplicationController
  before_action :require_logged_in!

  def feed
    @tweets = current_user.page_of_tweets(type: :feed, limit: params[:limit])
    render :feed
  end

  def index
    # simulate latency
    sleep(1)
    
    # Your code here
  end

  def create
    # simulate latency
    sleep(1)

    @tweet = current_user.tweets.build(tweet_params)
    if @tweet.save
      respond_to do |format|
        format.html { redirect_to user_url(current_user) }
        # Your code here
      end
    else
      errors = @tweet.errors.full_messages
      respond_to do |format|
        format.html do 
          flash[:errors] = errors
          redirect_to request.referrer 
        end
        # Your code here
      end
    end
  end

  private
  
  def tweet_params
    params.require(:tweet).permit(:body, :mentioned_user_id)
  end
end