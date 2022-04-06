class SessionsController < ApplicationController
  before_action :require_not_logged_in!, only: [:create, :new]
  before_action :require_logged_in!, only: [:destroy]

  def create
    if params[:demo].present?
      @user = User.find(params[:demo])
    else
      @user = User.find_by_credentials(
        params[:user][:username],
        params[:user][:password]
      )
    end

    if @user
      log_in!(@user)
      redirect_to feed_url
    else
      flash.now[:errors] = ['Invalid credentials']
      render :new
    end
  end

  def destroy
    log_out!
    
    redirect_to new_session_url
  end

  def new
    render :new
  end
end
