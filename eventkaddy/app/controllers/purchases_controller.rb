class PurchasesController < ApplicationController
	layout 'subevent_2013'
  before_action :authenticate_user!
  before_action :verify_as_admin
  before_action :set_event

	def index
		@purchases = AttendeeProduct.includes(:attendee, :transactions).where(attendee: {event_id: session[:event_id]})
	end

  def refund_purchases
    index
  end

  def exhibitor_purchases
    success_status = TransactionStatusType.where(iid: 'success').first
    @orders = Order.joins(:transaction_detail, user: :events)
               .where(events: { id: session[:event_id] })
               .where(transaction_detail: {
                transaction_status_type_id: success_status.id,
                attendee_id: [nil, ""] })

  end

  def attendee_purchases
    @orders = Order.joins(:transaction_detail, user: :events)
                  .where(events: {id: session[:event_id]})
                  .where(transaction_detail: {transaction_status_type_id: 3})
  end

  def item_purchases
    @products = Product
      .select(
        'products.name',
        'products.id AS products_id',
        'COUNT(products.id) AS count',
        'SUM(CASE WHEN orders.status = "paid" THEN 1 ELSE 0 END) AS paid_order_count',
        'SUM(CASE WHEN orders.status = "refund_completed" THEN 1 ELSE 0 END) AS refund_completed_order_count'
      )
      .joins("INNER JOIN order_items ON order_items.item_id = products.id")
      .joins("INNER JOIN orders ON orders.id = order_items.order_id")
      .where(event_id: session[:event_id])
      .where("orders.status IN (?)", ['paid', 'refund_completed'])
      .group("products.id")
    @result = @products.as_json(only: [ :name], methods: [:products_id, :count, :paid_order_count, :refund_completed_order_count])
  end

  def purchase_amount
    @products = Product
    .select(
      'products.name',
      'products.id AS products_id',
      'COUNT(products.id) AS count',
      'SUM(order_items.quantity) AS total_quantity',
      'SUM(
        CASE WHEN orders.status IN ("paid", "refund_completed") THEN (
          order_items.quantity * products.price
        ) ELSE 0 END
      ) AS total_product_order_amount',
      'SUM(
        CASE WHEN orders.status IN ("paid", "refund_completed") THEN (
          order_items.price
        ) ELSE 0 END
      ) AS total_paid_amount',
      'SUM(
        CASE WHEN orders.status IN ("paid") THEN (
          order_items.price
        ) ELSE 0 END
      ) AS total_amount',
      'SUM(
        CASE WHEN orders.status IN ("refund_completed") THEN (
          order_items.price
        ) ELSE 0 END
      ) AS total_refunded_amount'
    )
    .joins("INNER JOIN order_items ON order_items.item_id = products.id")
    .joins("INNER JOIN orders ON orders.id = order_items.order_id")
    .where(event_id: session[:event_id])
    .where("orders.status IN (?)", ['paid', 'refund_completed'])
    .group("products.id")
    .order(total_paid_amount: :desc, total_product_order_amount: :desc, total_amount: :desc, total_refunded_amount: :desc)

    @result = @products.as_json(only: [ :name], methods: [:products_id, :count, :total_product_order_amount, :total_paid_amount, :total_quantity, :total_amount, :total_refunded_amount])

    @total_amount = 0
    @amount_with_refund_money = 0
    @total_refunded_amount = 0

    @result.each do |product|
      @amount_with_refund_money += product['total_paid_amount']
      @total_amount += product['total_amount']
      @total_refunded_amount += product['total_refunded_amount']
    end

  end

  def transactions
    # @orders = Order.joins(user: :events).
    #                 where(events: { id: session[:event_id] })
    sql = <<~SQL
      SELECT DISTINCT *
      FROM (
        (SELECT orders.id, status, orders.user_id, orders.transaction_id, orders.total, orders.registration_form_id, orders.created_at, orders.updated_at
        FROM orders
        INNER JOIN users ON orders.user_id = users.id
        INNER JOIN users_events ON users_events.user_id = users.id
        WHERE users_events.event_id = :event_id)
        UNION
        (SELECT orders.id, status, orders.user_id, orders.transaction_id, orders.total, orders.registration_form_id, orders.created_at, orders.updated_at
        FROM orders
        WHERE registration_form_id IN (SELECT id FROM registration_forms WHERE event_id = :event_id))
      ) AS combined_results
      ORDER BY combined_results.created_at DESC;
    SQL
    @orders = Order.find_by_sql([sql, { event_id: session[:event_id] }])
  end

  def show_transactions
    order_id = params[:order_id]
    @order = Order.find order_id
  end

  def refund
    transaction = Transaction.find_by(id: params[:id])
    message = 'Something Went Wrong'
    if transaction
      result = PaymentGateways::PaypalRestApi.refund_order(transaction)
      message = "Payment Refuned" if result
    end
    redirect_to '/purchases', notice: message
  end

  def transaction_refund
    transaction = Transaction.find_by(id: params[:id])
    if transaction.present?
      event = Event.find transaction.mode_of_payment.event_id
      mode_of_payment = ModeOfPayment.find transaction.mode_of_payment_id
      order = Order.where(transaction_id: transaction.id).first
      if mode_of_payment.iid = "affinipay"
        refund_respond = PaymentGateways::AffinipayRestApi.create_refund(transaction.external_payment_id, transaction.amount*100, mode_of_payment.client_secret_key)
        response = JSON.parse refund_respond.body
        if refund_respond.code == "200"
          transaction.update_columns(
            external_refund_status: response["status"],
            external_refund_amount: response["amount"],
          )
          user = order.user
          attendee = Attendee.where( user_id: user.id, event_id: event.id )
          if attendee.present?
            AttendeeMailer.refund(
              event.id,
              attendee.first,
              transaction
              ).deliver
              order.update_attribute("status",'refund_intiated')
              unique_product_ids = user.orders.where(status: 'paid')
                                              .joins(:order_items)
                                              .distinct
                                              .pluck('order_items.item_id')
              uniq_product_category_ids = Product.where(id: unique_product_ids)
                                                 .pluck('DISTINCT product_categories_id')
              registration_setting      = Setting.return_cached_settings_for_registration_portal({ event_id: event.id })
              registration_category_ids = registration_setting.registration_category_ids
              is_register_order_item_present = false
              uniq_product_category_ids.each do |uniq_product_category_id|
                if registration_category_ids.include?(uniq_product_category_id.to_s)
                  is_register_order_item_present = true
                  if is_register_order_item_present == true
                    break
                  end
                end
              end
              if is_register_order_item_present == false
                attendee.first.update_attribute(:registration_status, false)
              end
          end
          redirect_to '/purchases/transactions', notice: "Refund Intiated!, it will take some time."
        else
          redirect_to '/purchases/transactions', alert: response['messages'][0]['message']
        end
      end
    end
  end

  def charge_id_refund
    charge_id = params[:charge_id]
    event_id  = session[:event_id]
    refund_respond = PaymentGateways::AffinipayRestApi.refund_by_charge_id(charge_id,event_id)
    order_transaction = OrderTransaction.where(transaction_id: charge_id).first
    response = JSON.parse refund_respond.body
    if response["id"].present?
      if order_transaction.present?
        order_transaction.update_columns(transaction_status: "REFUN_INTIATED")
        redirect_to '/purchases/transactions', notice: "Refund Intiated!, it will take some time."

      end
    else
      message  = response['messages'][0]['message']
      redirect_to '/purchases/transactions', alert: message
    end
  end

  def user
    order = Order.where(id: params[:order_id]).first
    if order.present?
      if order.user_id?
        redirect_to '/purchases/transactions/#{params[:order_id]}', alert: "User is already created."
        return
      else
        if order.registration_form_id?
          user = User.where(email: order.registration_form.email).first
          if user.present?
            redirect_to '/purchases/transactions/#{params[:order_id]}', alert: "User is already created."
            return
          else
            password = SecureRandom.base64(4)
            user_data = {
              :user => {
                  :password =>  password
              }
            }
            @user = User.new(
                email: order.registration_form.email,
                password: password,
                password_confirmation: password,
                first_name: order.registration_form.first_name,
                last_name: order.registration_form.last_name
              )
            @user.save!
            if !@user.confirmed_at?
              @user.confirm
            end
            @new_attendee = Attendee.new(order.registration_form.as_json(except: [:id, :status]))
            AttendeeMailer.registration_attendee_email_password(session[:event_id], @new_attendee, user_data).deliver
            @new_attendee.user_id = @user.id
            @new_attendee.password = password
            @new_attendee.save!
            attendee_role = Role.find_by(name: 'Attendee')

            users_event = UsersEvent.find_or_create_by(
              user_id: @user.id,
              event_id: session[:event_id]
            )

            UserEventRole.find_or_create_by(
              role_id: attendee_role.id,
              users_event_id: users_event.id
            )

            UsersRole.find_or_create_by(
              user_id: @user.id,
              role_id: attendee_role.id
            )

            order.update_columns(user_id: @user.id)
            redirect_to '/purchases/transactions/#{params[:order_id]}', notice: "User and attendee have been created, and their credentials have been sent to their respective emails."
            return
          end
        end
      end
    end
    redirect_to '/purchases/transactions', alert: "Something went wrong."
  end

 private
  def verify_as_admin
    raise "Your not authorized for this action" unless  (current_user.role?("Client") || current_user.role?("SuperAdmin"))
  end

  def set_event
    if session[:event_id].present?
      @event = Event.find_by(id: session[:event_id])
    end

    redirect_to root_url if @event.nil?
  end
end
