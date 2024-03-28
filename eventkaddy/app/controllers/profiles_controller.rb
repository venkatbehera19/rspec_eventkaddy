class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_user_role, except: [:account, :update_account]
  layout :set_layout

  def profile
    unless current_user.otp_required_for_login
      current_user.generate_two_factor_secret_if_missing!
    end
  end

  def update_general
    current_user.first_name = general_params[:first_name]
    current_user.last_name  = general_params[:last_name]
    current_user.save
    respond_to do |format|
      format.js
    end
  end

  def update_password
    current_user_id = current_user.id
    current_user.update_with_password(password_params)
    bypass_sign_in User.find(current_user_id), scope: :user
    # bypass_sign_in user, scope: :user
    # current_user_id = current_user.id
    # current_user.errors.add(:current_password, :invalid) unless current_user.valid_password?(password_params[:current_password])
    # if current_user.errors.blank?
    #  current_user.reset_password(password_params[:password], password_params[:password_confirmation])
    #  bypass_sign_in User.find(current_user_id)
    # end
    respond_to do |format|
      format.js
    end
  end

  def create_two_factor
    unless current_user.valid_password?(enable_2fa_params[:password])
      current_user.errors.add(:password, :invalid)
    end

    if current_user.validate_and_consume_otp!(enable_2fa_params[:code])
      current_user.enable_two_factor!
      @backup_codes = current_user.generate_otp_backup_codes!
      @success_message = "Successfully enabled two factor authentication, please make note of your backup codes."
      current_user.save
    else
      current_user.errors[:base] << "Incorrect Code"
    end
  end

  def two_factor
    if current_user.disable_two_factor!
      @success_message = 'Successfully disabled two factor authentication.'
      current_user.generate_two_factor_secret_if_missing!
    else
      current_user.errors[:base] << 'Could not disable two factor authentication.'
    end
  end

  def regenerate_backup_codes
    @success_message = "Your old backup codes are discarded, please make note of your new backup codes."
    @backup_codes = current_user.generate_otp_backup_codes!
    current_user.save
  end

  def account
    @user = current_user
  end

  def update_account
    @user = current_user
    @user.update(user_params)
    redirect_to '/'
  end

  private

  def general_params
    params.require(:user).permit(:first_name,:last_name,:email)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def enable_2fa_params
    params.require(:two_fa).permit(:code, :password).merge(code: params[:code])
  end

  def verify_user_role
    raise "Your not authorized for this action" unless (current_user.role?("SuperAdmin") || current_user.role?("Client"))
  end

  def set_layout
    if current_user.role? :Client
      'application_2013'
    elsif current_user.role? :SuperAdmin
      'superadmin_2013'
    elsif current_user.role? :Exhibitor
      'exhibitorportal'
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name)
  end

end
