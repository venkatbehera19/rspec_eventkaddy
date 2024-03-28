module AuthenticateWithOtpTwoFactor
  include Devise::Controllers::Rememberable
  extend ActiveSupport::Concern


  def authenticate_with_otp_two_factor
    user = self.resource = find_user
    # if user.locked_at? 
    #   flash.now[:alert] = I18n.t('devise.failure.locked', name: user.email).html_safe
    #   return render "managers/sessions/new", locals: { resource: :user }
    # end
    if user_params[:otp_attempt].present? && user_params[:id]
      authenticate_user_with_otp_two_factor(user)
    elsif user&.valid_password?(user_params[:password])
      prompt_for_otp_two_factor(user)
    end
  end

  private

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(user_params[:otp_attempt]) ||
        user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end

  def prompt_for_otp_two_factor(user)
    @user = user
    @remember_me = user_params[:remember_me]
    @login_h3_content = "Sign In"
    return render 'managers/sessions/two_factor'
  end

  def authenticate_user_with_otp_two_factor(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      remember_me(user) if user_params[:id] == '1'
      user.reset_two_factor_token = nil if !user.reset_two_factor_token.blank?
      user.save!
      set_flash_message!(:notice, :signed_in)
      sign_in(user, event: :authentication)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash.now[:alert] = 'Invalid two-factor code.'
      prompt_for_otp_two_factor(user)
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :remember_me, :otp_attempt, :id)
  end

  def find_user
    if user_params[:id]
      @user = User.find(user_params[:id])
    elsif user_params[:email]
      @user = User.find_by(email: user_params[:email])
    end
  end

  def otp_two_factor_enabled?
    find_user&.otp_required_for_login
  end

end