class UsersController < ApplicationController
  before_action :require_not_logged_in!, only: [:create, :new]
  before_action :require_logged_in!, only: [:show, :search]

  def create
    @user = User.new(user_params)

    if @user.save
      log_in!(@user)
      redirect_to feed_url
    else
      flash.now[:errors] = @user.errors.full_messages
      render :new
    end
  end

  def new
    @user = User.new # dummy user (view expects @user to be defined)
    render :new
  end

  def show
    @user = User.includes(tweets: :mentioned_user).find(params[:id])
    render :show
  end

  def search
    # simulate latency
    sleep(0.5)

    if params[:query].present?
      @users = User.where("username iLIKE ?", params[:query] + "%")
    else
      @users = User.none
    end

    render :search
  end

  protected
  
  def user_params
    self.params.require(:user).permit(:username, :password)
  end
end