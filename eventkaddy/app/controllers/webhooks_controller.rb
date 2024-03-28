class WebhooksController < ApplicationController
  layout 'subevent_2013'
  skip_before_action :verify_authenticity_token
  before_action :verify_as_admin, only: [:index]


  def index
    @webhooks = Webhook.order(created_at: :desc)
  end

  def show
    @webhook = Webhook.find params[:id]
  end

  # it is handle for accepting affinipay Events
  def affinipay
    Rails.logger.info 'Inside Affinipay Payment call_back'

    if params.present?
      webhooks = Webhook.where(transaction_id: params["data"]["id"])
      if webhooks.present?
        webhook = webhooks.first
        if webhook.event_type == 'transaction.authorized' && params["type"] != 'transaction.authorized'
          webhook.update_columns(
            event_id: params['id'],
            event_type: params["type"],
            status: params["data"]["status"]
          )
        end
      else
        Webhook.create(
          event_id: params['id'],
          event_type: params["type"],
          transaction_id: params["data"]["id"],
          status: params["data"]["status"],
          amount: params["data"]["amount"],
          email: params["data"]["method"]["email"],
        )
      end
      process_payment_event(params["type"], params["data"])
    end
  end

  def refund
    charge_id = params[:charge_id]
    event_id  = session[:event_id]
    refund_respond = PaymentGateways::AffinipayRestApi.refund_by_charge_id(charge_id,event_id)
    order_transaction = OrderTransaction.where(transaction_id: charge_id).first
    response = JSON.parse refund_respond.body
    if response["id"].present?
      if order_transaction.present?
        order_transaction.update_columns(transaction_status: "REFUN_INTIATED")
        redirect_to '/webhooks', notice: "Refund Intiated!, it will take some time."

      end
    else
      message  = response['messages'][0]['message']
      redirect_to '/webhooks', alert: message
    end
  end

  private

  def process_payment_event(event_type, data)
    case event_type
    when 'transaction.authorized'
      Rails.logger.info "<--Authorized--> <--#{event_type}-->"
    when 'transaction.completed'
      Rails.logger.info "<--Completed--> <--#{event_type}-->"
      if data['type'] == 'REFUND' && data['status'] == 'COMPLETED'
        process_refund_data data
      else
        process_complete_event data
      end
    when 'transaction.voided'
      Rails.logger.info "<--voided--> <--#{event_type}-->"
      process_voided_event data
    when 'transaction.failed'
      Rails.logger.info "<--failed--> <--#{event_type}-->"
      process_failed_event data
    when 'transaction.updated'
      Rails.logger.info "<--updated--> <--#{event_type}-->"
      process_update_event data
    end
    render json: { status: true }
  end

  def process_complete_event data

    transaction_id = data["id"]
    order_transaction = OrderTransaction.find_by(transaction_id: transaction_id)

    if order_transaction && order_transaction.transaction_status != 'COMPLETED'
      order = order_transaction.order
      order_transaction.update_column(:transaction_status, data["status"])
      if order.status != "paid"
        order.update_column(:status, "paid")
        coupon_item = order.order_items.where.not(coupon_id: nil)
        registered_user = order.registration_form_id ? order.registration_form : order.user
        users = User.where(email: registered_user.email)

        if users.present?
          @user = users.first
        else
          password = SecureRandom.base64(4)
          @user = User.create(
            email: registered_user.email,
            password: password,
            password_confirmation: password,
            first_name: registered_user.first_name,
            last_name: registered_user.last_name
          )
          @user_data = {
            :user => {
              :password =>  password
            }
          }
        end

        if !@user.confirmed_at?
          @user.confirm
        end

        if coupon_item.present?
          coupon = Coupon.find coupon_item.first.coupon_id
          coupon_code_usage = CouponCodeUsage.create(
            coupon_id: coupon.id,
            user_id: @user.id
          )
          coupon.decrement_remaining_usage
        end

        if order.registration_form_id?
          attendee_role = Role.find_by(name: 'Attendee')
          UsersRole.create!(
            user_id: @user.id,
            role_id: attendee_role.id
          )
          # create attendee
          new_attendee = Attendee.new(order.registration_form.as_json(except: [:id, :status]))
          # assign user
          new_attendee.user_id = @user.id
          new_attendee.save!
          AttendeeMailer.registration_attendee_email_password(
            new_attendee.event_id,
            new_attendee, user_data
          ).deliver
        end
        # response.body
        response_data = JSON.parse response.body
        # assign attendee to tarnsaction
        #external_payment_id => affinipay payment ID (charge_id)
        amount = response_data["amount"]/100
        transaction = Transaction.create(
            amount: amount,
            external_status: response_data["status"],
            transaction_status_type: TransactionStatusType.success,
            attendee_id: new_attendee.id,
            mode_of_payment_id: mode_of_payment_id,
            external_payment_id: response_data["id"]
          )
        order.update_columns(transaction_id: transaction.id, user_id: @user.id)
        if order.registration_form_id?
          order.registration_form.update_attribute(:status, "success")
        end
      end
    end
  end

  def process_failed_event data
    transaction_id = data["id"]
    order_transaction = OrderTransaction.find_by(transaction_id: transaction_id)

    if order_transaction && order_transaction.transaction_status != 'FAILED'
      order_transaction.update_column(:transaction_status, data["status"])

      order = order_transaction.order
      order.update_column(:status, "failed")
    end
  end

  def process_update_event data
    transaction_id = data["id"]
    order_transaction = OrderTransaction.find_by(transaction_id: transaction_id)

    if order_transaction && order_transaction.transaction_status != 'UPDATED'
      order_transaction.update_column(:transaction_status, data["status"])

      order = order_transaction.order
      order.update_column(:status, "failed")
    end
  end

  def process_refund_data data
    order_transaction = OrderTransaction.where(transaction_id: data["charge_id"]).first
    if order_transaction.present?
      order_transaction.update_columns(transaction_status: 'REFUND_COMPLETED')
    end
    transaction = Transaction.where(external_payment_id: data["charge_id"]).first
    if transaction
      transaction.update_columns(
        external_refund_status: data["status"],
        external_refund_amount: data["amount"],
        external_refund_completion_at: data["completion_timestamp"]
      )
      mode_of_payment = ModeOfPayment.find transaction.mode_of_payment_id
      order = Order.where(transaction_id: transaction.id).first
      order.update_attribute("status",'refund_completed')
      if mode_of_payment.iid = "affinipay"
        if order.present?
          attendee = order.user.attendee
          AttendeeMailer.refund_complete(
            attendee.event_id,
            attendee,
            transaction
          ).deliver
        end
      end
    end
  end

  def process_voided_event data
    transaction_id = data["id"]
    order_transaction = OrderTransaction.find_by(transaction_id: transaction_id)

    if order_transaction && order_transaction.transaction_status != 'VOIDED'
      order_transaction.update_column(:transaction_status, data["status"])
    end
  end

  def verify_as_admin
    raise "Your not authorized for this action" unless  current_user.role?("SuperAdmin")
  end

end
