module PaymentGateways
	class StripeClient
		attr_accessor :stripe_key

		def initialize(payment_gateway)
			self.stripe_key = payment_gateway.client_secret_key
		end

		def get_or_create_customer customer
			Stripe.api_key = stripe_key
			full_name = "#{customer.first_name} #{customer.last_name}".strip
			search_customer = Stripe::Customer.search({
			  query: "name:\'#{full_name}\' AND email:\'#{customer.email}\'",
			})

			if search_customer.data.present?
				stripe_customer_id = search_customer.data.first.id
			else
				stripe_customer = Stripe::Customer.create({
					name: full_name,
					email: customer.email
				})
				stripe_customer_id = stripe_customer.id
			end
			stripe_customer_id
		end

		def create_payment_intent transaction, stripe_customer_id
			Stripe.api_key = stripe_key

			payment_intent = Stripe::PaymentIntent.create(
				amount: (transaction.product.price * 100).to_i,
				currency: 'usd',
				automatic_payment_methods: {
					enabled: true,
				},
				customer: stripe_customer_id
			)

			transaction.update(external_payment_id: payment_intent.id, external_status: payment_intent.status, external_cust_id: stripe_customer_id)

			return payment_intent['client_secret']
		end

		def create_payment_intent_cart transaction, stripe_customer_id, cart
			Stripe.api_key = stripe_key

			total = cart.cart_items.reduce(0) do |sum, item|
					if item.item_type == 'Product'
						sum = sum + (item.item.price * item.quantity )
					else  
						sum = sum + (item.item.products.first.price * item.quantity)
					end  
					sum
				end
			payment_intent = Stripe::PaymentIntent.create(
				amount: (total * 100).to_i,
				currency: 'usd',
				automatic_payment_methods: {
					enabled: true,
				},
				customer: stripe_customer_id
			)

			transaction.update(external_payment_id: payment_intent.id, external_status: payment_intent.status, external_cust_id: stripe_customer_id)

			return payment_intent['client_secret']
		end

		def create_payment_intent_cart_registration_form transaction, stripe_customer_id, cart
			Stripe.api_key = stripe_key

			total = cart.registration_form_cart_items.reduce(0) do |sum, item|
					if item.item_type == 'Product'
						sum = sum + (item.item.price * item.quantity )
					else  
						sum = sum + (item.item.products.first.price * item.quantity)
					end  
					sum
				end
			payment_intent = Stripe::PaymentIntent.create(
				amount: (total * 100).to_i,
				currency: 'usd',
				automatic_payment_methods: {
					enabled: true,
				},
				customer: stripe_customer_id
			)

			transaction.update(external_payment_id: payment_intent.id, external_status: payment_intent.status, external_cust_id: stripe_customer_id)

			return payment_intent['client_secret']
		end

		def create_payment_intent_cart_attendee transaction, stripe_customer_id, cart
			Stripe.api_key = stripe_key

			total = cart.cart_items.reduce(0) do |sum, item|
					if item.item_type == 'Product'
						sum = sum + (item.item.price * item.quantity )
					else  
						sum = sum + (item.item.products.first.price * item.quantity)
					end  
					sum
				end
			payment_intent = Stripe::PaymentIntent.create(
				amount: (total * 100).to_i,
				currency: 'usd',
				automatic_payment_methods: {
					enabled: true,
				},
				customer: stripe_customer_id
			)

			transaction.update(external_payment_id: payment_intent.id, external_status: payment_intent.status, external_cust_id: stripe_customer_id)

			return payment_intent['client_secret']
		end

		def create_payment_intent_order_attendee stripe_customer_id, order
			Stripe.api_key = stripe_key
			total = order.order_items.reduce(0) do |sum, item|
				if item.item_type == 'Product'
					sum = sum + (item.item.price * item.quantity )
				else  
					sum = sum + (item.item.products.first.price * item.quantity)
				end  
				sum
			end
			payment_intent = Stripe::PaymentIntent.create(
				amount: (total * 100).to_i,
				currency: 'usd',
				automatic_payment_methods: {
					enabled: true,
				},
				customer: stripe_customer_id
			)
			return payment_intent
		end

		class << self
			def create_payment(transaction, register_form)
				object = self.new(transaction.mode_of_payment)
				stripe_customer_id = object.get_or_create_customer(register_form)
				object.create_payment_intent(transaction, stripe_customer_id)
			end

			def create_payment_cart(transaction, cart)
				object = self.new(transaction.mode_of_payment)
				stripe_customer_id = object.get_or_create_customer(cart.user)
				object.create_payment_intent_cart(transaction, stripe_customer_id, cart)
			end

			def create_payment_registration_form_cart(transaction, cart)
				object = self.new(transaction.mode_of_payment)
				stripe_customer_id = object.get_or_create_customer(cart.registration_form)
				object.create_payment_intent_cart_registration_form(transaction, stripe_customer_id, cart)
			end

			def create_payment_cart_attendee(transaction, cart)
				object = self.new(transaction.mode_of_payment)
				stripe_customer_id = object.get_or_create_customer(cart.user)
				object.create_payment_intent_cart_attendee(transaction, stripe_customer_id, cart)
			end

			def create_payment_order_form (mode_of_payment, order)
				object = self.new(mode_of_payment)
				customer = order.user || order.registration_form
				stripe_customer_id = object.get_or_create_customer(customer)
				object.create_payment_intent_order_attendee(stripe_customer_id, order)
			end
			
		end
	end
end