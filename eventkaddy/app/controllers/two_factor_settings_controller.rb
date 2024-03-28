class TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user! #, :unless => proc {confirmation_link?}
  before_action :verify_as_admin #,    :unless => proc {confirmation_link?}
  before_action :set_user
  layout 'superadmin_2013'

  def new
    if @user.otp_required_for_login
      flash[:alert] = 'Two Factor Authentication is already enabled.'
      return redirect_to "/users/#{@user.id}/edit"
    end
    
    @user.generate_two_factor_secret_if_missing!
  end

  def create
    unless @user.valid_password?(enable_2fa_params[:password])
      flash.now[:alert] = 'Incorrect password'
      render :new and return
    end

    if @user.validate_and_consume_otp!(enable_2fa_params[:code])
      @user.enable_two_factor!

      flash[:notice] = 'Successfully enabled two factor authentication, please make note of your backup codes.'
      redirect_to edit_two_factor_settings_path(id: @user.id) and return
    else
      flash.now[:alert] = 'Incorrect Code'
      render :new and return
    end
  end

  def edit
    unless @user.otp_required_for_login
      flash[:alert] = 'Please enable two factor authentication first.'
      redirect_to new_two_factor_settings_path(id: @user.id) and return
    end

    if @user.two_factor_backup_codes_generated?
      flash[:alert] = 'You have already seen your backup codes.'
      return redirect_to "/users/#{@user.id}/edit"
    end

    @backup_codes = @user.generate_otp_backup_codes!
    @user.save!
  end

  def destroy
    if @user.disable_two_factor!
      flash[:notice] = 'Successfully disabled two factor authentication.'
      redirect_to "/users/#{@user.id}/edit" and return
    else
      flash[:alert] = 'Could not disable two factor authentication.'
      redirect_to "/users/#{@user.id}/edit" and return
    end
  end

  # Discarded code for both xhr and http request
  # def create
  #   unless @user.valid_password?(enable_2fa_params[:password])
  #     if request.xhr?
  #       @user.errors.add(:password, :invalid)
  #     else
  #       flash.now[:alert] = 'Incorrect password'
  #       render :new and return
  #     end
  #     # flash.now[:alert] = 'Incorrect password'
  #     # render :new and return
  #   end

  #   if @user.validate_and_consume_otp!(enable_2fa_params[:code])
  #     @user.enable_two_factor!
  #     if !request.xhr?
  #       flash[:notice] = 'Successfully enabled two factor authentication, please make note of your backup codes.'
  #       redirect_to edit_two_factor_settings_path(id: @user.id) and return
  #     end
  #   else
  #     if request.xhr?
  #       @user.errors.add_to_base("Incorrect Code")
  #     else
  #       flash.now[:alert] = 'Incorrect Code'
  #       render :new and return
  #     end
  #     # flash.now[:alert] = 'Incorrect Code'
  #     # render :new and return
  #   end

  #   respond_to do |format|
  #     format.html
  #     format.js
  #   end

  # end
  private


  def set_user
    @user = User.find(params[:id])
  end

  def verify_as_admin
    raise "Your not authorized for this action" unless current_user.role?("SuperAdmin")
  end

  def enable_2fa_params
    params.require(:two_fa).permit(:code, :password).merge(code: params[:code])
  end

  # def confirmation_link?
  #   begin
  #     path = Rails.application.routes.recognize_path(request.referrer)
  #   rescue  
  #     path = Rails.application.routes.recognize_path(request.referrer, method: :post)
  #   end
  #   return ( path[:controller] == "invitations" && path[:action] == "show" )
  # end

  # def verify_as_admin_or_same_user
  #   unless current_user == @user
  #     unless current_user.role?("SuperAdmin")
  #       raise "Your not authorized for this action"
  #     end
  #   end
  #   # raise "Your not authorized for this action" unless current_user.role?("SuperAdmin")
  # end


  # def set_layout
  #   if current_user.role? :moderator then
  #     'moderatorportal'
  #   else
  #     'subevent_2013'
  #   end
  # end

end
