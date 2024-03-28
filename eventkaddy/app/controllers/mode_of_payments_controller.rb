class ModeOfPaymentsController < ApplicationController

  before_action :authenticate_user!
  before_action :verify_as_admin
  before_action :set_event
  before_action :set_payment, only: [:edit, :update, :show]
  layout :set_layout

  def index
    @payments = ModeOfPayment.where(event: @event)
  end

  def edit
  end

  def update
    len   = ActiveSupport::MessageEncryptor.key_len
    salt  = SecureRandom.random_bytes(len)
    key   = ActiveSupport::KeyGenerator.new(ENV["SALT"]).generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    encrypted_data = crypt.encrypt_and_sign(payment_param.to_json)
    if @payment.update(
        credentials: encrypted_data,
        key: key,
        environment: params[:mode_of_payment][:environment],
        merchant_account_id: params[:mode_of_payment][:merchant_account_id],
        merchant_partner_name: params[:mode_of_payment][:merchant_partner_name]
      )
      redirect_to mode_of_payments_path, notice: "Saved Successfully"
    else
      render :edit
    end
  end

  private

  def payment_param
  	params.require(:mode_of_payment).permit(:client_key, :client_secret_key, :environment, :merchant_account_id, :merchant_partner_name)
  end


  def verify_as_admin
    raise "Your not authorized for this action" unless  (current_user.role?("Client") || current_user.role?("SuperAdmin"))
  end

  def set_layout
    if current_user.role? :speaker
      'speakerportal_2013'
    elsif current_user.role? :exhibitor
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def set_event
  	@event = Event.find_by(id: session[:event_id])
  	redirect_to root_url if @event.blank?
  end

  def set_payment
    @payment = ModeOfPayment.find_by(id: params[:id])
  end
end
