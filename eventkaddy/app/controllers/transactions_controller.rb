class TransactionsController < ApplicationController
	layout 'customized_registrations'
	skip_before_action :verify_authenticity_token
	before_action :set_ga_key, :get_settings, :set_attendee, :check_attendee_transaction ,only: [:new, :get_merchant_form, :create]
	before_action :set_ga_key, :get_exhibitor_settings, :set_exhibitor, only: [:exhibitor_select_booth, :get_merchant_form_exhibitor]


	def new
		mode_of_payment_id = Transaction.payment_available?(@settings)
		if mode_of_payment_id.present?
			@payment = ModeOfPayment.find_by(id: mode_of_payment_id)
			if @payment.name == 'Stripe'

			elsif @payment.name == 'PayPal'
				@client_id = @payment.client_key
			end
		end
	end

	def get_merchant_form
		product = Product.find_by(id: params[:product_id])
		mode_of_payment_id = Transaction.payment_available?(@settings)
		mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
		if product && mode_of_payment.can_make_payment? && @register_form
			begin
				if mode_of_payment.name == 'PayPal'
					@paypal_env = mode_of_payment.environment
				elsif mode_of_payment.name == 'Stripe'
					@stripe_env = mode_of_payment.client_key
				end
				@transaction = Transaction.find_by_id(params['transaction_id']) if params['transaction_id'] != 'undefined'
				@transaction = Transaction.new(mode_of_payment: mode_of_payment, transaction_status_type: TransactionStatusType.pending) if @transaction.blank?
				@transaction.product_id = product.id
				@transaction.save

			rescue StandardError => e
				@error_message = e.message
			end
		else
			@error_message = "Fields Missing To Make Payment"
		end

		if mode_of_payment.name == 'Stripe'
			render partial: 'get_merchant_stripe_form'
		elsif mode_of_payment.name == 'PayPal'
			render partial: 'get_merchant_form'
		end
	end

	def create
		transaction = Transaction.find_by(id: params["transaction"]["id"], external_payment_id: params["transaction"]["charge_id"])
		attendee = transaction.attendee
		product = transaction.product
		if transaction.transaction_status_type.success?
			attendee_product = AttendeeProduct.create(attendee: attendee, product: product, membership_id: params[:transaction][:membership_id])
			transaction.attendee_product_id = attendee_product.id
			transaction.save
			@settings.send_calendar_invite && CalendarInviteMailer.invite(params[:event_id], attendee, @settings.attach_calendar_invite).deliver_now
			token =  Base64.encode64({email: attendee.email, created_at: DateTime.now}.to_json)
			attendee.update_attribute('token', token)
			render json: {url: "/#{attendee.event_id}/registrations/registered/#{attendee.slug}"}, status: 200
		else
			transaction.transaction_status_type = TransactionStatusType.failed
			transaction.save
			render json: {message: "Transaction failed for Payment ID : #{transaction.external_payment_id}"},status: 400
		end
	end

	def paypal_create_payment
		transaction = Transaction.find_by(id: params[:transaction][:id])
		#event_id = transaction.attendee.event_id
		result = PaymentGateways::PaypalRestApi.create_order_id(transaction)
		if result
			render json: { token: result }, status: :ok
		else
			render json: {error: "Something Went Wrong, transaction unsuccessful"}, status: :unprocessable_entity
		end
	end

	def paypal_execute_payment
		#result = PaymentGateways::Paypal.make_payment(params[:paymentID], params[:payerID])
		register_form = RegistrationForm.find_by(id: params[:registerFormId])
		result = PaymentGateways::PaypalRestApi.complete_order(params[:orderID], params[:payerID], register_form)
		if result
			render json: {message: 'PAYMENT_COMPLETE'}, status: :ok
		else
			render json: {error: "Something Went Wrong, transaction unsuccessful"}, status: :unprocessable_entity
		end
	end

	def stripe_create_payment
		transaction = Transaction.find_by(id: params[:transaction][:id])
		cart = Cart.find_by(id: params[:transaction][:cart_id])
		register_form = RegistrationForm.find_by(id: params["transaction"]["register_form"])
		begin
			if cart
				booth_item = cart.cart_items.find_by(item_type: 'LocationMapping')
				booth = booth_item.item
				if booth.locked_by != cart.user_id
					transaction.update(transaction_status_type: TransactionStatusType.failed, external_status: "Booth Locked By Other User, Can't Proceed further")
					render json: {error: "Booth Locked By Other User, Can't Proceed further"}, status: :unprocessable_entity
				else
					clientSecret = PaymentGateways::StripeClient.create_payment_cart(transaction, cart)
					render json: {clientSecret: clientSecret}
				end
			elsif register_form
				clientSecret = PaymentGateways::StripeClient.create_payment(transaction, register_form)
				render json: {clientSecret: clientSecret}
			end
		rescue StandardError => e
			transaction.update(transaction_status_type: TransactionStatusType.failed, external_status: e.message)
			render json: {error: e.message}, status: :unprocessable_entity
		end
	end

	def payment
		payment_id     = params[:payment_id]
		event_id       = params[:event_id]
		order_id       = params[:order_id]
		cart_id        = params[:cart_id]

		# transaction    = Transaction.find_by(id: transaction_id)
		order          = Order.find order_id
		cart           = Cart.find(cart_id)
		begin

			if !cart
				return handle_failed_transaction(transaction, "Cart not found")
			end

			booth_item = order.order_items.find_by(item_type: 'LocationMapping')

			if booth_item.present?
				if !booth_item.item.is_available?
					if !booth_item.item.locked_by == cart.user_id
						redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", notice: 'Booth is not available.'
						return
					end
				end
				booth = booth_item.item

				if booth.locked_by != cart.user_id
					return handle_failed_transaction(transaction, "Booth Locked By Other User, Can't Proceed further")
				end
			end

			cart_items_product_ids          = cart.cart_items.where( item_type: "Product" ).pluck(:item_id)
			products                        = Product.where( id: cart_items_product_ids )
			category_ids                    = products.pluck( :product_categories_id )
			sponsorship_with_booth_category = ProductCategory.find_by( iid: 'sponsorship_with_booth', event_id: params[:event_id] )

			if sponsorship_with_booth_category && category_ids.include?(sponsorship_with_booth_category.id)
				sponsorship_with_booth_category_product = sponsorship_with_booth_category.products.where(id: cart_items_product_ids).first
				if sponsorship_with_booth_category_product && sponsorship_with_booth_category_product.available_qantity == 0
					return handle_failed_transaction(transaction, "Product isn't available")
				end
			end

			mode_of_payment_id = Transaction.payment_available?(get_exhibitor_settings)
			if !mode_of_payment_id.present?
				redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", alert: 'Payment mode is not availabale right now.'
			end

			mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
			# response = PaymentGateways::AffinipayRestApi.create_payment_exhibitor(transaction, cart, payment_id)
			response = PaymentGateways::AffinipayRestApi.create_payment_exhibitor_v2(mode_of_payment, payment_id, order, category_ids, @settings)
    	response_data = JSON.parse(response.body)

			if response.code == '422'
				if response_data["messages"].present?
					render json: { status: false,  message: response_data["messages"] }
					return
				end
			end

			if response.code != "200" && response.code != "422"
				return handle_failed_transaction(transaction, "Payment Gateway Error")
			end

			amount = response_data["amount"]/100
			transaction = Transaction.create(
        amount: amount,
        external_status: response_data["status"],
        transaction_status_type: TransactionStatusType.success,
        mode_of_payment_id: mode_of_payment_id,
        external_payment_id: response_data["id"],
				cart_id: cart.id
      )

      order.update_columns(transaction_id: transaction.id, user_id: cart.user_id, status: 'paid')

			success = cart.update_attribute(:status, "payment_successfull")
			# order   = Order.find_by(transaction_id: transaction.id)

			if !success || !order
				return handle_failed_transaction(transaction, "Failed to update cart or order")
			end

			exhibitor     = Exhibitor.find_by(user_id: cart.user_id, event_id: event_id)
			if exhibitor.nil?
				user = User.find cart.user_id
				user_exhibitor_params = JSON.parse user.json
				exhibitor_params      = user_exhibitor_params.transform_keys(&:to_sym)

				exhibitor = Exhibitor.new(
          event_id: event_id,
          user_id: user.id,
          company_name: exhibitor_params[:company],
          city: exhibitor_params[:city],
          state: exhibitor_params[:state],
          country: exhibitor_params[:country],
          email: user.email,
          phone: exhibitor_params[:mobile_phone],
          url_twitter: exhibitor_params[:twitter_url],
          url_facebook: exhibitor_params[:facebook_url],
          url_linkedin: exhibitor_params[:linked_in]
        )
				exhibitor.save
				user_event = user.users_events.find_or_create_by(event_id: event_id)
				role       = Role.where(name: 'Exhibitor').first
				UserEventRole
          .find_or_create_by(role_id: role.id, users_event_id: user_event.id)
				UsersRole.find_or_create_by(role_id: role.id, user_id: user.id)
			end

			# Exhibitor Mailer for recipt
			ExhibitorMailer.send_recipt(event_id, exhibitor, order).deliver
			receipt_email = @settings.receipt_email
			if receipt_email.present?
				ExhibitorMailer.send_recipt(event_id, exhibitor, order, receipt_email).deliver_later
			end
			if current_user.present?
				staff_details = order.calculate_staff_from_products event_id, exhibitor
			else
				staff_details = order.calculate_staff_from_products event_id
			end

			if sponsorship_with_booth_category && category_ids.include?(sponsorship_with_booth_category.id)
				sponsorship_with_booth_category_product = sponsorship_with_booth_category.products.where(id: cart_items_product_ids).first
				location_mapping = LocationMapping.find_by(product_id: sponsorship_with_booth_category_product.id)
				sponsorship_with_booth_category_product.update_attribute(:available_qantity, 0)
				exhibitor.update_attribute(:location_mapping_id, location_mapping.id)
			end

			exhibitor.update_attribute(:staffs, staff_details.as_json)
			render_success_response(order, transaction, cart)


		rescue StandardError => e
			handle_failed_transaction(transaction, "Unable to do the transaction!. #{e.message}")
		end

	end

	def exhibitor_zero_total_payment
		event_id       = params[:event_id]
		transaction_id = params[:transaction_id]
		cart_id        = params[:cart_id]

		transaction    = Transaction.find_by(id: transaction_id)
		cart           = Cart.find(cart_id)

		if !cart
			return handle_failed_transaction(transaction, "Cart not found")
		end

		if !transaction
			return handle_failed_transaction(transaction, "Transaction not found")
		end

		cart.create_order(transaction)
		order = Order.where(transaction_id: transaction.id).first
		order.update_attribute(:status, "paid")
		success = cart.update_attribute(:status, "payment_successfull")
		transaction.update_attribute(:external_status, 'SUCCESS')

		if !success || !order
			return handle_failed_transaction(transaction, "Failed to update cart or order")
		end

		exhibitor     = Exhibitor.find_by(user_id: cart.user_id, event_id: event_id)
		ExhibitorMailer.send_recipt(event_id, exhibitor, order).deliver
		staff_details = order.calculate_staff_from_products event_id, exhibitor
		exhibitor.update_attribute(:staffs, staff_details.as_json)
		render_success_response(order, transaction, cart)
	end

	def stripe_complete_payment
		@transaction = Transaction.find_by(external_payment_id: params["payment_intent"])
		register_form = RegistrationForm.find_by(id: params["registerFormId"])
		event_id = register_form.event_id
		settings = Setting.return_cached_settings_for_registration_portal({ event_id: event_id })
		Stripe.api_key = @transaction.mode_of_payment.client_secret_key
		stripe_payment = Stripe::PaymentIntent.retrieve(params['payment_intent'])

		if stripe_payment.status == 'succeeded'
			attendee = Attendee.new(register_form.as_json(except: :id))
			attendee.save
			attendee_product = AttendeeProduct.create(attendee: attendee, product: @transaction.product, membership_id: params["memId"])
			@transaction.update(amount: stripe_payment.amount_received/100, external_status: stripe_payment.status, transaction_status_type: TransactionStatusType.success, attendee: attendee, attendee_product_id: attendee_product.id)

			settings.send_calendar_invite && CalendarInviteMailer.invite(event_id, attendee, settings.attach_calendar_invite).deliver_now

			token =  Base64.encode64({email: attendee.email, created_at: DateTime.now }.to_json)
			attendee.update_attribute('token', token)
			redirect_to "/#{attendee.event_id}/registrations/registered/#{attendee.slug}"
		else
			@transaction.update(external_status: stripe_payment.status)
			@error = "Something Went Wrong"
		end
	end

	def exhibitor_select_booth
		event_id        = params[:event_id]
		@userMisMatched = (session[:exhibitor_registration_id] || current_user&.id) != params[:id].to_i
		@user           = User.find_by(id: params[:id])
		map_type        = MapType.find_by_map_type('Interactive Map')
		@event_map      = EventMap.joins(location_mappings: :products).find_by(map_type_id: map_type.id, event_id: event_id)
		@cart           = Cart.find_or_create_by(user: @exhibitor)

		@cart.update(status: 'on_product_select_page')

		product_category_ids = @settings.product_categories_ids
    @product_category    = ProductCategory.where(id: product_category_ids);

		@product_category_with_product  = ProductCategory.joins(:products).where(id: product_category_ids).order(:order).uniq

		cart_items_product_ids          = @cart.cart_items.where( item_type: "Product" ).pluck(:item_id)
		products                        = Product.where( id: cart_items_product_ids )
		category_ids                    = products.pluck( :product_categories_id )
		sponsorship_with_booth_category = ProductCategory.find_by( iid: 'sponsorship_with_booth', event_id: event_id )

		if sponsorship_with_booth_category && category_ids.include?(sponsorship_with_booth_category.id)
			sponsorship_with_booth_category_product = sponsorship_with_booth_category.products.where(id: cart_items_product_ids).first
			if sponsorship_with_booth_category_product
				@sponsorship_with_booth_category_product = true
			end
		end

		sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )
		if sponsorship_with_booth_selection_category && category_ids.include?(sponsorship_with_booth_selection_category.id)
			sponsorship_with_booth_selection_category_product = sponsorship_with_booth_selection_category.products.where(id: cart_items_product_ids).first
			if sponsorship_with_booth_selection_category_product
				@sponsorship_with_booth_selection_category_product = true
			end
		end
	end


	def exhibitor_add_to_cart
		location_mapping = LocationMapping.where(id: params[:booth]).first

		if location_mapping.present?
			cart = Cart.find_by(user_id: params[:user_id])
			cart_item_in_cart = cart.cart_items.find_by(item_type: location_mapping.class.name)
			cart_item_in_cart.destroy if cart_item_in_cart # deleting same type of product already present in cart
			cart_item_added = CartItem.create(item_id: location_mapping.id, item_type: location_mapping.class.name, cart_id: cart.id)
			item_id    = location_mapping.id
			item_type  = 'Booth'
			item_name  = location_mapping.name
			item_price = location_mapping.products.first.price
			item_added = {
				item_type: item_type,
				item_name: item_name,
				item_price: item_price,
				item_id: item_id
			}
			render json: {
									status: true,
									message: "Added To Cart",
									item_added: item_added,
								}, status: :ok
			return
		end

		user    										= User.find params[:user_id] || current_user.id
		product 										= Product.find params[:product_id]
		type    										= params[:type]
		category_exclusions 				= CategoryExclusion.
																	where( excluded_category_id: product.product_category.id ).
    															pluck(:category_id)
		category_exclusions_reverse = CategoryExclusion.
																	where(category_id: product.product_category.id).
    															pluck(:excluded_category_id)
		if !product.is_product_available?
			render json: { message: "Product is Unavilable" }, status: :ok
			return
		end

		item_id    = product.id
		item_type  = 'Product'
		item_name  = product.name
		item_price = product.price
		item_added = {
			item_type:  item_type,
			item_name:  item_name,
			item_price: item_price,
			item_id:    item_id
		}

		cart             = Cart.find params[:cart_id]
		product_category = ProductCategory.find params[:category_id]
		if product_category.is_single_select_product?
			if !cart.check_category_item_is_present_in_cart? (product_category)
				if type == 'remove'
					cart_item = CartItem.find_by(
																item_id: product.id,
																item_type: product.class.name,
																cart_id: cart.id
															)
					cart_item.delete
					total_cart_item = cart.cart_items.reduce(0){|sum,item| sum+=item.quantity}
					render json: {
									status: true,
									message: "Product Removed Successfully",
									type: type,
									data: cart_item,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									cart_count: total_cart_item
								}, status: :ok
					return
				elsif type == 'add'
					if product_category.iid == 'sponsorship_with_booth'
						cart = Cart.find params[:cart_id]
						cart_items = cart.cart_items.where(item_type: 'LocationMapping')
						if cart_items.present?
							cart_items.first.delete
						end
					end
					cart_item_added = CartItem.find_or_create_by(
																			item_id: product.id,
																			item_type: product.class.name,
																			cart_id: cart.id
																		)
					total_cart_item = cart.cart_items.reduce(0){|sum,item| sum+=item.quantity}
					map_type        = MapType.find_by_map_type('Interactive Map')
					@event_map      = EventMap.joins(location_mappings: :products).find_by(map_type_id: map_type.id, event_id: product_category.event_id)
					if product_category.iid == 'sponsorship_with_booth_selection'
						location_mapping_with_product_associated = @event_map.location_mappings
						.joins(:location_mapping_products)
						.where(locked_by: nil, product_id: nil)
						.select{|booth| booth.products.first.iid == 'premium_location' || booth.products.first.iid == 'corner_booth' || booth.products.first.iid == 'standard_in-line' }
					else
						location_mapping_with_product_associated = @event_map.location_mappings
						.joins(:location_mapping_products)
						.where(locked_by: nil, product_id: nil)
						.select{|booth|(
							booth.products.first.iid != 'premium_location'
						)}
					end
					already_bought    = LocationMapping
															.joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id')
															.where(order_items: {item_type: 'LocationMapping'})
															.uniq
					already_booked_lm = Exhibitor
															.joins(:location_mapping)
															.where(event_id: product_category.event_id)
															.pluck(:'location_mappings.id')
															.uniq
					location_mapping_both      = LocationMapping.where(id: already_booked_lm)
					available_location_mapping = (location_mapping_with_product_associated - already_bought) - location_mapping_both
					available_location_mapping_data = available_location_mapping.map do |booth| { booth_id: booth.id, booth_name: booth.name, product_name: booth.products.first.name, product_price: booth.products.first.price } end
					render json: {
									status: true,
									message: "Product Added Successfully",
									type: type,
									data: cart_item_added,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									item_added: item_added,
									cart_count: total_cart_item,
									is_sponser_with_booth: product_category.iid == 'sponsorship_with_booth',
									is_sponser_with_booth_selection: product_category.iid == 'sponsorship_with_booth_selection',
									available_location_mapping: available_location_mapping_data
								}, status: :ok
					return
				end
			else
				if type == 'remove'
					cart_item = CartItem.find_by(
																item_id: product.id,
																item_type: product.class.name,
																cart_id: cart.id
															)
					cart_item.delete

					total_cart_item = cart.cart_items.reduce(0){|sum,item| sum+=item.quantity}
					map_type        = MapType.find_by_map_type('Interactive Map')
					@event_map      = EventMap.joins(location_mappings: :products).find_by(map_type_id: map_type.id, event_id: product_category.event_id)
					location_mapping_with_product_associated =  @event_map.location_mappings
					.joins(:location_mapping_products)
					.where(locked_by: nil, product_id: nil)
					.select{|booth|(
						booth.products.first.iid != 'premium_location'
					)}

					already_bought    = LocationMapping
															.joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id')
															.where(order_items: {item_type: 'LocationMapping'})
															.uniq
					already_booked_lm = Exhibitor
															.joins(:location_mapping)
															.where(event_id: product_category.event_id)
															.pluck(:'location_mappings.id')
															.uniq
					location_mapping_both      = LocationMapping.where(id: already_booked_lm)
					available_location_mapping = (location_mapping_with_product_associated - already_bought) - location_mapping_both
					available_location_mapping_data = available_location_mapping.map do |booth| { booth_id: booth.id, booth_name: booth.name, product_name: booth.products.first.name, product_price: booth.products.first.price } end

					render json: {
									status: true,
									message: "Product Removed Successfully",
									type: type,
									data: cart_item,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									item_added: item_added,
									cart_count: total_cart_item,
									is_sponser_with_booth_selection: product_category.iid == 'sponsorship_with_booth_selection',
									available_location_mapping: available_location_mapping_data
								}, status: :ok
					return
				else
					render json: {
									status: false,
									message: "Can't add this product to cart.",
								}, status: :ok
					return
				end
			end
		else
			if type == 'increase'
				cart_item_added = CartItem.find_by(
					item_id: product.id,
					item_type: product.class.name,
					cart_id: cart.id
				)
				if !cart_item_added.present?
					cart_item_added = CartItem.create(
						item_id: product.id,
						item_type: product.class.name,
						cart_id: cart.id
					)
				else
					quantity = cart_item_added.quantity
					cart_item_added.update_columns(quantity: quantity + 1)
				end
			else
				cart_item_added = CartItem.find_by(
					item_id: product.id,
					item_type: product.class.name,
					cart_id: cart.id
				)
				if cart_item_added.present?
					quantity = cart_item_added.quantity
					cart_item_added.update_columns(quantity: quantity - 1)
					if quantity-1 == 0
						cart_item_added.delete
					end
				else
					render json: { status: false, message: "Add the product to cart before removing it." }, status: :ok
					return
				end
			end
			total_cart_item = cart.cart_items.reduce(0){|sum,item| sum+=item.quantity}
			render json: {
				status: true,
				message: "product updated sucessfully",
				data: cart_item_added ,
				category_exclusions: category_exclusions,
				category_exclusions_reverse: category_exclusions_reverse,
				type: type,
				item_added: item_added,
				cart_count: total_cart_item
				}, status: :ok
			return
		end
	end

	def exhibitor_remove_from_cart
		cart = Cart.find_by(user_id: params[:user_id])
		sponsor_level_type = SponsorLevelType.find_by(id: params[:sponsor_id])
		if sponsor_level_type
			item = cart.cart_items.find_by(item_id: sponsor_level_type.id)
			item.destroy
			message = 'Item Removed'
		else
			message = 'Item Not Found'
		end
		total_cart_item = cart.cart_items.reduce(0){|sum,item| sum+=item.quantity}
		render json: {status: :ok, message: message, item_id: sponsor_level_type&.id, cart_count: total_cart_item}
	end

	# def exhibitor_payment_v2
	# 	get_exhibitor_settings
	# 	@cart = Cart.find_by(id: params[:cart_id])
	# 	@userMisMatched = (session[:exhibitor_registration_id] || current_user&.id) != @cart.user_id
	# 	if @userMisMatched
	# 		redirect_to root_url
	# 	end
	# 	@cart.status = 'on_payment_page'
	# 	@cart.save
	# 	booth_item = @cart.cart_items.find_by(item_type: 'LocationMapping')
	# 	booth_item_bought_earlier = @cart.user.orders.flat_map { |order| order.order_items.select { |item| item.item_type == LocationMapping } }

	# 	cart_items_product_ids          = @cart.cart_items.where( item_type: "Product" ).pluck(:item_id)
	# 	products                        = Product.where( id: cart_items_product_ids )
	# 	@category_ids                    = products.pluck( :product_categories_id )
	# 	sponsorship_with_booth_category = ProductCategory.find_by( iid: 'sponsorship_with_booth', event_id: params[:event_id] )
	# 	@sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: params[:event_id] )
	# 	if sponsorship_with_booth_category && @category_ids.include?(sponsorship_with_booth_category.id)
	# 		sponsorship_with_booth_category_product = sponsorship_with_booth_category.products.where(id: cart_items_product_ids).first
	# 		if sponsorship_with_booth_category_product && sponsorship_with_booth_category_product.available_qantity > 0
	# 			set_up_transaction
	# 		else
	# 			cart_item = @cart.cart_items.where(item_id: sponsorship_with_booth_category_product.id).first
	# 			if cart_item.present?
	# 				cart_item.delete
	# 			end
	# 			redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{@cart.user_id}/select_booth", alert: 'Cart Items are unavailable'
	# 		end
	# 	elsif booth_item
	# 		booth = booth_item.item
	# 		if ( booth.locked_by && booth.locked_by != @cart.user_id )
	# 			redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{@cart.user_id}/select_booth", alert: 'Booth has been currently locked IN'
	# 		else
	# 			booth.locked_by = @cart.user_id
	# 			if booth.locked_at
	# 				@timer = booth.locked_at + 10.minute
	# 				if DateTime.now.utc > @timer
	# 					booth.locked_by = nil
	# 					booth.locked_at = nil
	# 					booth.save
	# 					redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{@cart.user_id}/select_booth", alert: "Time's Up, reselect the booth and try again"
	# 				end
	# 			else
	# 				BoothOwnerWorker.perform_in(600, booth.id)
	# 				booth.locked_at = DateTime.now.utc
	# 				booth.save
	# 				@timer = booth.locked_at + 10.minute
	# 			end
	# 			set_up_transaction
	# 		end
	# 	elsif booth_item_bought_earlier.present?
	# 		set_up_transaction
	# 	else
	# 		redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{@cart.user_id}/select_booth", alert: 'No Booth Selected'
	# 	end
	# end

	def exhibitor_payment
		event_id = params[:event_id]
		get_exhibitor_settings
		@cart = Cart.find_by(id: params[:cart_id])
		@userMisMatched = (session[:exhibitor_registration_id] || current_user&.id) != @cart.user_id

		if @userMisMatched
			redirect_to root_url
		end
		@cart.status = 'on_payment_page'
		@cart.save

		@order = Order.find params[:order_id]
		user = @cart.user

		location_mapping = @order.order_items.where(item_type: 'LocationMapping').first

		if location_mapping.present?
			booth_available = OrderItem.joins(:order).where(item_id: location_mapping.item_id).where(orders: {status: 'paid'})
		end

		if booth_available.present?
			location_mapping.delete
			redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", alert: 'Booth is unavailable, please select another booth'
		end

		if location_mapping.present?
			if !location_mapping.item.is_available?
				if !location_mapping.item.locked_by == @cart.user_id
					redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", notice: 'Booth is not available.'
				end
			end
		end

		# booth_item_bought_earlier = OrderItem.joins(:order).where(item_type:'LocationMapping').where(orders: {status: 'paid', user_id: user.id})
		# if booth_item_bought_earlier.present?
		# 	# already purchased
		# end

		mode_of_payment_id = Transaction.payment_available?(get_exhibitor_settings)
    if !mode_of_payment_id.present?
			redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", alert: 'Payment mode is not availabale right now.'
    end

		@mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
		if @mode_of_payment.name == 'Stripe'
			@stripe_env = @mode_of_payment.client_key
		elsif @mode_of_payment.name == 'PayPal'
			@client_id = @mode_of_payment.client_key
		end


		sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )
    product_category_ids                      = @settings.product_categories_ids
    cart_items                                = @cart.cart_items.includes(:item).where(item_type: 'Product')
    category_ids                              = cart_items.map { |item| item.item.product_categories_id }.uniq

		@total  = @order.calculate_total_order_amount_v2(sponsorship_with_booth_selection_category, category_ids)
		booth_item = location_mapping&.item
		if booth_item.present?
			if (booth_item.locked_by && booth_item.locked_by != @cart.user_id)
				redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", alert: 'Booth has been currently locked IN'
			else
				booth_item.locked_by = @cart.user_id
				if booth_item.locked_at
					@timer = booth_item.locked_at + 10.minute
					if DateTime.now.utc > @timer
						booth_item.locked_by = nil
						booth_item.locked_at = nil
						booth_item.save
						redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", alert: "Time's Up, reselect the booth and try again"
					end
				else
					BoothOwnerWorker.perform_in(600, booth_item.id)
					booth_item.locked_at = DateTime.now.utc
					booth_item.save
					@timer = booth_item.locked_at + 10.minute
				end
			end
		end
	end

	def create_payment_for_exhibitor
		transaction = Transaction.find_by(id: params[:transaction][:id])
		cart = Cart.find_by(id: params[:transaction][:cart_id])
		result = PaymentGateways::PaypalRestApi.create_order_id_for_exhibitor(transaction, cart)
		if result
			render json: { token: result }, status: :ok
		else
			render json: {error: "Something Went Wrong, transaction unsuccessful"}, status: :unprocessable_entity
		end
	end

	def execute_payment_for_exhibitor
		transaction = Transaction.find_by(external_payment_id: params[:orderID])
		event = transaction.mode_of_payment.event_id
		cart = transaction.cart
		booth_item = cart.cart_items.find_by(item_type: 'LocationMapping')
		booth = booth_item&.item
		if booth && booth.locked_by != cart.user_id
			render json: {error: "Time Up or Locking Up the Booth", url: "/#{params[:event_id]}/exhibitor_registrations/payment/#{cart.user_id}/select_booth"}, status: :unprocessable_entity
		else
			result = PaymentGateways::PaypalRestApi.complete_order_for_exhibitor(params[:orderID], params[:payerID])
			if result
				render json: {message: 'PAYMENT_COMPLETE'}, status: :ok
			else
				render json: {error: "Something Went Wrong, transaction unsuccessful"}, status: :unprocessable_entity
			end
		end
	end

	def exhibitor_payment_success
		transaction = Transaction.find_by(id: params[:transaction][:id])
		cart = Cart.find_by(id: params[:transaction][:cart_id])
		event_id = transaction.mode_of_payment.event_id
		exhibitor = cart.user.exhibitors.find_by(event_id: event_id)
		exhibitor.set_location_mapping_after_purchase(cart)
		exhibitor.set_sponsor_level_type_after_purchase(cart)
		exhibitor.update(reg_payment_done: true)
		cart.cart_items.destroy_all

		render json: {url: "/#{event_id}/exhibitor_registrations/#{cart.user_id}/payment_success"}, status: 200
	end

	def exhibitor_affinipay_payment_success
		event_id       = params[:event_id]
		transaction_id = params[:transaction_id]
		transaction    = Transaction.find transaction_id
		if !transaction.present?
			redirect_to('/', alert: 'Something Went Wrong.')
		end
		cart           = transaction.cart
		if !cart
			redirect_to('/', alert: 'Something Went Wrong.')
		end
		user      = cart.user
		exhibitor = user.exhibitors.find_by(event_id: event_id)
		exhibitor.set_location_mapping_after_purchase(cart)
		exhibitor.update(reg_payment_done: true)
		cart.cart_items.destroy_all
		current_user = user
    sign_in(current_user)
    session[:event_id] = event_id
    if current_user && current_user.role?(:exhibitor)
      redirect_to "/exhibitor_portals/landing"
    end
	end

	def stripe_complete_payment_exhibitor
		@transaction = Transaction.find_by(external_payment_id: params["payment_intent"])
		cart = Cart.find_by(id: params["cartId"])
		event_id = @transaction.mode_of_payment.event_id
		Stripe.api_key = @transaction.mode_of_payment.client_secret_key
		stripe_payment = Stripe::PaymentIntent.retrieve(params['payment_intent'])
		if stripe_payment.status == 'succeeded'
			@transaction.update(amount: stripe_payment.amount_received/100, external_status: stripe_payment.status, transaction_status_type: TransactionStatusType.success)
			cart.update(status: 'payment_success')
			cart.create_order(@transaction)
			exhibitor = cart.user.exhibitors.find_by(event_id: event_id)
			exhibitor.set_location_mapping_after_purchase(cart)
			exhibitor.set_sponsor_level_type_after_purchase(cart)
			exhibitor.update(reg_payment_done: true)
			cart.cart_items.destroy_all
			notice = "Payment Successful"
		else
			@transaction.update(external_status: stripe_payment.status)
			notice = "Something Went Wrong"
		end

		redirect_to "/#{event_id}/exhibitor_registrations/#{cart.user_id}/payment_success", notice: notice
	end

	def set_up_transaction
		mode_of_payment_id = Transaction.payment_available?(get_exhibitor_settings)
		if mode_of_payment_id.present?
			@mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
			if @mode_of_payment.name == 'Stripe'
				@stripe_env = @mode_of_payment.client_key
			elsif @mode_of_payment.name == 'PayPal'
				@client_id = @mode_of_payment.client_key
			end
			@transaction = Transaction.find_by(cart: @cart, transaction_status_type: TransactionStatusType.pending)
			@transaction && (@transaction.mode_of_payment != @mode_of_payment) && @transaction.update(mode_of_payment: @mode_of_payment)
			@transaction = Transaction.create(mode_of_payment: @mode_of_payment, transaction_status_type: TransactionStatusType.pending, cart: @cart ) if @transaction.nil?
			location_mapping_cart_items = @cart.cart_items.where( item_type: 'LocationMapping').first
			if location_mapping_cart_items.present?
				product = location_mapping_cart_items&.item&.products&.first
				if product.present?
					@maximum_complimentary_staff = product.maximum_complimentary_staff
					@maximum_discount_staff      = product.maximum_discount_staff
				end
			end
			@total = 0
			@cart.cart_items.each do |cart_item|

				if cart_item.item_type == 'Product'

					if cart_item.item.product_category.iid == 'staff_members'
						@discount_allocation = DiscountAllocation.find_or_initialize_by(cart_item: cart_item, event_id: params[:event_id], user_id: @cart.user_id)

						@discount_allocation.
						apply_discount(
							cart_item.quantity,
							@maximum_complimentary_staff,
							@maximum_discount_staff,
							cart_item.item.member_price,
							cart_item.item.price
						)
						@total = @total + @discount_allocation.amount
					else
						@total = @total + (cart_item.item.price * cart_item.quantity )
					end
				elsif cart_item.item_type == 'LocationMapping'
					if @sponsorship_with_booth_selection_category && @category_ids.include?(@sponsorship_with_booth_selection_category.id)
						discount_allocation_booth = DiscountAllocation.find_or_initialize_by(
							cart_item: cart_item,
							event_id: params[:event_id],
							user_id: @cart.user_id
						)
						discount_allocation_booth.apply_discount_booth(cart_item.item.products.first.member_price)

						@total = @total + discount_allocation_booth.amount
					else
						@total = @total + (cart_item.item.products.first.price * cart_item.quantity )
					end
				else
					@total = @total + (cart_item.item.products.first.price * cart_item.quantity )
				end

			end
		end
	end

	private

	def get_settings
		@settings = Setting.return_cached_settings_for_registration_portal({ event_id:params[:event_id] })
	end

	def get_exhibitor_settings
		@settings = Setting.return_exhibitor_registration_portal_settings(params[:event_id])
	end

	def set_attendee
		@register_form = RegistrationForm.find_by(id: params[:id])
		@attendee = Attendee.find_by(event_id: @register_form.event_id, email: @register_form.email) if @register_form
	end

	def set_exhibitor
		@exhibitor = User.find_by_id(params[:id]) #exhibitor type user
	end

	def check_attendee_transaction
		if @attendee && Transaction.find_by(attendee: @attendee, transaction_status_type: TransactionStatusType.success)
			if request.xhr?
				render json: {url: "/#{params[:event_id]}/registrations/registered/#{@attendee.slug}"}
			else
				redirect_to "/#{params[:event_id]}/registrations/registered/#{@attendee.slug}"
			end
		end
	end

	def handle_failed_transaction transaction, error_message
		transaction.update(transaction_status_type: TransactionStatusType.failed, external_status: error_message)
		render json: { error: error_message }, status: :unprocessable_entity
	end

	def render_success_response order, transaction, cart
		render json: {
			message: "Payment Successful",
			status: true,
			order_id: order.id,
			transaction_id: transaction.id,
			email: cart.user.email,
			amount: transaction.amount,
			time: transaction.created_at,
			user_id: cart.user.id
		}, status: :ok
	end

end
