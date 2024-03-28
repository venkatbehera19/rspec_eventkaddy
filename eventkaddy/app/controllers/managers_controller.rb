class ManagersController < Devise::SessionsController
#	layout false
	include AuthenticateWithOtpTwoFactor
	prepend_before_action :authenticate_with_otp_two_factor, if: -> { action_name == 'create' && otp_two_factor_enabled? && !@user.locked_at? }
	before_action :set_flash_message_with_link!, only: :new

	#override devise's built-in new action
	def new
		self.resource = resource_class.new(sign_in_params)
	# @login_h3_content = "Sign In"
		respond_to do |format|
			format.html { render :action => "sessions/new" }
		end
		# respond_with(resource, serialize_options(resource))
	end

	def create
		if  !!resource && !resource.confirmed_at?
			flash[:alert] = I18n.t('devise.failure.unconfirmed').html_safe
			return redirect_to new_session_path(resource_name)
		end
		#super
		resource = User.find_by(email: params[:user][:client_iid])
		if resource && resource.valid_password?(params[:user][:client_digest])
			sign_in(resource)
			if params[:user][:is_attendee] == "true"
				attendee = Attendee.where(event_id: params[:event_id], user_id: resource.id).first
				if attendee.present?
					redirect_to "/attendee_portals/landing/#{attendee.slug}"
				else
					cookies.clear
					current_user = nil
					reset_session
					redirect_to "/#{params[:event_id]}/registrations/login_to_profile", alert: "User cannot access the login feature through the attendee portal."
					return
				end
			else
				respond_with resource, location: after_sign_in_path_for(resource)
			end
		else
			flash[:alert] = I18n.t('devise.failure.invalid').html_safe
			if !params[:user][:is_attendee]
				return redirect_to new_session_path(resource_name)
			else
				redirect_to "/#{params[:event_id]}/registrations/login_to_profile"
			end
		end
		!!params[:event_id] && session[:event_id] = params[:event_id]
	end

	def after_sign_out_path_for(resource_or_scope)
		(request.referrer.include? "registrations")? request.referrer : new_user_session_path
	end

	protected

	# making html_safe flash messages with lock flash message and confirm flash message. Don't know why but devise gives user in params when redirecting from create method to new if user is locked but not when user is confirmed.
	def set_flash_message_with_link!
		if !params[:user].nil?
			email = params[:user][:client_iid]
			user = User.where(email: email).first
			if !!user&.locked_at?
				if user.failed_attempts == Devise.maximum_attempts
					flash.now[:alert] = I18n.t('devise.failure.locked_first') if flash[:alert]
				else
					flash.now[:alert] = flash[:alert].html_safe if flash[:alert]
				end
			end
		else
			flash.now[:alert] = flash[:alert].html_safe if flash[:alert]
		end
	end


	def sign_in_params
		#devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:client_iid, :client_digest, :remember_me) }
		devise_parameter_sanitizer.sanitize(:sign_in)
	end
end
