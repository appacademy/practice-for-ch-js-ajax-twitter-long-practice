class FollowsController < ApplicationController
  before_action :require_logged_in!

  def create
    # simulate latency
    sleep(1)

    follow = current_user.out_follows.create!(following_id: params[:user_id])

    respond_to do |format|
      format.html { redirect_to request.referrer }
    end
  end

  def destroy
    # simulate latency
    sleep(1)

    follow = current_user.out_follows.find_by(following_id: params[:user_id])
    follow.destroy!

    respond_to do |format|
      # Set redirect status to `:see_other` (303) to force a `GET` request. 
      # Otherwise, some browsers will keep the method of the redirect as 
      # `DELETE`.
      # See https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_to
      format.html { redirect_to request.referrer, status: :see_other }
    end
  end
end