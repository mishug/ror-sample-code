class ApplicationController < ActionController::Base
  protect_from_forgery

  after_filter :store_location
  before_filter :assign_user_to_session_itinerary
  before_filter :init_empty_enquiry

  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    rescue_from NoMethodError, :with => :no_method_found
  end

  def store_location
    not_returnable = %w[/sign_in /sign_up /users/sign_out]
    session[:previous_urls] ||= []
    # store unique urls only
    session[:previous_urls].prepend request.fullpath if session[:previous_urls].first != request.fullpath && !not_returnable.include?(request.fullpath)
    session[:previous_urls].pop if session[:previous_urls].count > 2
  end

  def after_sign_in_path_for(resource)
    session[:request_quote_url] || session[:previous_urls].last || root_path
  end

  private

  def assign_user_to_session_itinerary
    if session[:itinerary_id] and current_user
      itinerary = Itinerary.find session[:itinerary_id]
      itinerary.update_attribute :user , current_user
      session[:itinerary_id] = nil
    end
  end

  def init_empty_enquiry
    @enquiry = Enquiry.new
  end

  def no_method_found
    flash[:error] = "The resource you are trying to access cannot be found on our system."
    logger.error "Someone tried to access #{request.filtered_parameters} but NoMethodError was given."
    redirect_to root_path
  end

  def record_not_found
    flash[:error] = "The resource you are trying to access cannot be found on our system."
    redirect_to root_path
  end
end
