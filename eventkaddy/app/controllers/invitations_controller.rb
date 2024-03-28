class InvitationsController <  Devise::ConfirmationsController
  before_action :set_user, only: [:show, :show_with_two_factor, :confirm_without_two_factor, :confirm_with_two_factor]


  def show
  end

  def confirm_without_two_factor
    @user.reset_password(params[:user][:password], params[:user][:password_confirmation])
    if @user.errors.empty?
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?

      if resource.errors.empty?
        flash.now[:alert] = I18n.t('devise.invitations.confirmed')
        redirect_to "/users/sign_in", notice: I18n.t('devise.invitations.confirmed') and return
      else
        render :show and return
      end
    else
      render :show and return
    end
  end

  def show_with_two_factor
    @user.confirmed_at? and return redirect_to root_url, alert: 'User already confirmed!'
    @user.generate_two_factor_secret_if_missing!
  end

  def confirm_with_two_factor
    @user.reset_password(params[:user][:password], params[:user][:password_confirmation])
    if @user.errors.empty?
      if @user.validate_and_consume_otp!(params[:code])
        @user.enable_two_factor!
      else
        @user.errors.add(:base,"OTP code is empty or invalid.")
        render :show_with_two_factor and return
      end
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?
      if resource.errors.empty?
        redirect_to "/users/backup_codes?id=#{@user.id}", notice: "Successfully confirmed account and enabled two factor authentication, please make note of your backup codes." and return
      else
        render :show_with_two_factor and return
      end
    else
      render :show_with_two_factor and return
    end
  end

  def edit
    @user = User.find(params[:id].to_i)
    @user.blank? and return redirect_to new_user_session_path, alert: 'User not found.'
    verify_user_role

    unless @user.otp_required_for_login
      flash[:alert] = 'Please enable two factor authentication first.'
      redirect_to new_user_session_path and return
    end

    if @user.two_factor_backup_codes_generated?
      flash[:alert] = 'You have already seen your backup codes.'
      redirect_to new_user_session_path and return
    end

    @backup_codes = @user.generate_otp_backup_codes!
    @user.save!
  end


  
  private

  def set_user
    token = params[:confirmation_token]
    token.blank? and return redirect_to new_confirmation_path(resource_name), alert: 'Empty Token or Invalid verification link.'

    @user = User.find_by_confirmation_token(token)
    @user.blank? and return redirect_to new_confirmation_path(resource_name), alert: 'Empty Token or Invalid verification link.'
  end

  def verify_user_role
    raise "Your not authorized for this action" unless (@user.role?("SuperAdmin") || @user.role?("Client"))
  end

end