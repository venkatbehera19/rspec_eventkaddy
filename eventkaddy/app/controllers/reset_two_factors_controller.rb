class ResetTwoFactorsController < ApplicationController
  before_action :set_user_with_token, except: [:lost_device]
  before_action :verify_user_role, except: [:lost_device]
  layout 'application_2013'

  # generate two-factor lost device mail
  def lost_device
    set_user
    verify_user_role
    @user.generate_two_factor_token!
    TwoFactorsMailer.reset_two_factor_mail(@user).deliver_now
    redirect_to new_user_session_path, notice: I18n.t('devise.two_factor.reset_mail') and return
  end

  def new
    unless @user.otp_required_for_login
      redirect_to new_user_session_path, alert: "Two Factor Authentication is not enabled with your account." and return
    end
    
    @user.generate_two_factor_secret_if_missing!
    @user.save
  end

  def create
    unless @user.valid_password?(enable_2fa_params[:password])
      flash.now[:alert] = 'Incorrect password'
      render :new and return
    end

    if @user.validate_and_consume_otp!(enable_2fa_params[:code])
      @user.enable_two_factor!
      # @user.remove_existing_backup_codes!
      flash[:notice] = 'Successfully reset two factor authentication, please make note of your backup codes.'
      redirect_to edit_reset_two_factor_path(reset_two_factor_token: @user.reset_two_factor_token) and return
    else
      flash.now[:alert] = 'Incorrect Code'
      render :new and return
    end
  end

  def edit
    unless @user.otp_required_for_login && @user.confirmed_at?
      flash[:alert] = 'Please enable two factor authentication first.'
      return redirect_to new_user_session_path
    end

    if @user.reset_two_factor_token.nil?
      flash[:alert] = 'You have already seen your backup codes.'
      redirect_to new_user_session_path and return
    end

    @user.reset_two_factor_token = nil
    # @user.save!
    @backup_codes = @user.generate_otp_backup_codes!
    @user.save!
  end

  private

  def set_user
    @user = User.find(params[:id].to_i)
    @user.blank? and return redirect_to new_user_session_path, alert: "User not found."
  end

  def set_user_with_token
    token = params[:reset_two_factor_token]
    token.blank? and return redirect_to new_user_session_path, alert: I18n.t('devise.two_factor.invalid_token')

    @user = User.find_by_reset_two_factor_token(token)
    @user.blank? and return redirect_to new_user_session_path, alert: I18n.t('devise.two_factor.invalid_token')
  end

  def verify_user_role
    raise "Your not authorized for this action" unless (@user.role?("SuperAdmin") || @user.role?("Client"))
  end

  def enable_2fa_params
    params.require(:two_fa).permit(:code, :password).merge(code: params[:code])
  end

end
