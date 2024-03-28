# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  
  # GET /resource/password/new
  # def new
  #   super
  # end

  # GET /resource/password/new
  def new
    if (true || request.domain == AUTHORISED_STAGING_DOMAIN || request.domain == AUTHORISED_LOCAL_DOMAIN)
      super
    else
      set_flash_message!(:alert, :false_domain)
      render "managers/sessions/new", locals: { resource: :user }
    end
  end

  # POST /resource/password
  def create
    unless params[:user][:email].present?
      super and return
    end
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      set_flash_message!(:notice, :send_paranoid_instructions)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      set_flash_message!(:notice, :send_paranoid_instructions)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
