module Attendees
  class PaymentsController < ApplicationController
    layout :set_layout

    before_action :get_settings, only: [:new]

    def new
      order_id  = params[:order_id]
      @event_id = current_user.attendee.event_id
      @cart = current_user.cart
      @user = current_user
      @order = Order.find(order_id)
      @registration_url = "/attendees/products"
      coupon_item = @order.order_items.where.not(coupon_id: nil)
      if coupon_item.present?
        @coupon = coupon_item.first.coupon
      end
      mode_of_payment_id = Transaction.payment_available?(get_settings)
      if mode_of_payment_id.present?
        @mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
      end

      if @mode_of_payment.name == 'Stripe'
        @stripe_env = @mode_of_payment.client_key

      elsif @mode_of_payment.name == 'PayPal'
        @client_id = @mode_of_payment.client_key
      end

      @total = @order.order_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.price * item.quantity )
        else
          sum = sum + (item.item.products.first.price * item.quantity)
        end
        sum
      end

    end

    def confirm_payment
      payment_intent     = params['payment_intent']
      mode_of_payment_id = params["mode_of_payment_id"]
      order = Order.find(params['order_id'])
      stripe_payment = Stripe::PaymentIntent.retrieve(params['payment_intent'])
      event_id = params[:event_id]
      if stripe_payment.status == 'succeeded'
        order.update_column(:status, 'paid');
        transaction = Transaction.create(
          amount: stripe_payment.amount_received/100,
          external_cust_id: stripe_payment.customer,
          external_status: stripe_payment.status,
          transaction_status_type: TransactionStatusType.success,
          attendee_id: order.user.attendee.id,
          external_payment_id: stripe_payment.id,
          mode_of_payment_id: mode_of_payment_id
        )

        order.update_column(:transaction_id, transaction.id)
        order.update_column(:user_id, order.user.id)
        notice = "Payment Successful"
      else
        order.update_column(:status, 'failed');
        notice = "Something Went Wrong"
      end
      redirect_to "/attendee_portals/my_orders", notice: notice
    end

    private
    def get_settings
      @settings = Setting.return_cached_settings_for_registration_portal({ event_id: current_user.attendee.event_id })
    end

    def set_layout
      @current_user = current_user
      if current_user.role? :attendee then
        'attendeeportal'
      else
        'subevent_2013'
      end
    end

  end
end
