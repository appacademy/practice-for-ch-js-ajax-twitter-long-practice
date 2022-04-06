class ApplicationController < ActionController::Base
  helper_method :current_user
  before_action -> { params.deep_transform_keys!(&:underscore) }

  def current_user
    return nil if session[:session_token].nil?
    @current_user ||= User.find_by(session_token: session[:session_token])
  end

  def log_in!(user)
    session[:session_token] = user.reset_session_token!
  end

  def log_out!
    current_user.reset_session_token! if current_user
    session[:session_token] = nil
  end

  def require_logged_in!
    redirect_to new_session_url if current_user.nil?
  end

  def require_not_logged_in!
    redirect_to feed_url unless current_user.nil?
  end
end
