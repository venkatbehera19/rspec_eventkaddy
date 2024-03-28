module PaymentGateways
  class PaypalRestApi
    require "uri"
    require "net/http"

    attr_accessor :token, :base_url
    
    def initialize(payment_gateway)
      # paypal authorize
      return "Missing Credentials" if payment_gateway.blank? 

      if payment_gateway.environment == 'live'
        self.base_url = "https://api-m.paypal.com"
      else
        self.base_url = "https://api-m.sandbox.paypal.com"  
      end 

      url = URI("#{base_url}/v1/oauth2/token")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request.basic_auth payment_gateway.client_key, payment_gateway.client_secret_key
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = "grant_type=client_credentials&ignoreCache=true&return_authn_schemes=true&return_client_metadata=true&return_unconsented_scopes=true"

      response = https.request(request)
      if response.code == "200"
        self.token = JSON.parse(response.read_body)["access_token"]
      else
        self.token = ""
      end
    end

    def create_order(transaction)
      product = transaction.product

      url = URI("#{base_url}/v2/checkout/orders")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Prefer"] = "return=representation"
      # request["PayPal-Request-Id"] = "b4e9d187-a114-41ee-a6aa-be81b0cedc87"
      request["Authorization"] = "Bearer #{token}"
      request.body = JSON.dump({
        "intent": "CAPTURE",
        "purchase_units": [
          {
            "items": [
              {
                "name": product.description,
                "description": product.description,
                "quantity": "1",
                "unit_amount": {
                  "currency_code": "USD",
                  "value": product.price.to_s
                }
              }
            ],
            "amount": {
              "currency_code": "USD",
              "value": product.price.to_s,
              "breakdown": {
                "item_total": {
                  "currency_code": "USD",
                  "value": product.price.to_s
                }
              }
            },
            "description":  "Payment for: #{product.description}"
          }
        ]
      })

      begin
        response = https.request(request)
        response_json = JSON.parse(response.read_body)
        if response.code == "201"
          id = response_json["id"]
          status = response_json["status"]
          transaction.external_status = status
          transaction.external_payment_id = id
          return id if transaction.save
        else
          status = response_json["status"] || response_json["details"][0]["issue"] rescue nil || response_json["message"]
          transaction.external_status = status
          transaction.save
          return false
        end  
      rescue StandardError => e
        transaction.update(external_status: e.message)
      end

    end

    def execute_payment(order_id, payer_id, transaction, register_form)
      url = URI("#{base_url}/v2/checkout/orders/#{order_id}/capture")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Prefer"] = "return=representation"
      # request["PayPal-Request-Id"] = "08fc4105-49a0-4a1a-892c-90aaa1eee5d4"
      request["Authorization"] = "Bearer #{token}"
      begin
        response = https.request(request)
        update_transaction(transaction, response, payer_id, register_form)
      rescue StandardError => e
        transaction.update(external_status: e.message)
      end
    end

    def update_transaction(transaction, response, payer_id, register_form)
      response_json = JSON.parse(response.read_body)
      if response.code == "201"
        transaction.transaction_status_type = TransactionStatusType.success
        paypal_transaction = response_json["purchase_units"][0]["payments"]["captures"][0]

        transaction.external_cust_id = payer_id
        transaction.external_transaction_id = paypal_transaction["id"]
        transaction.amount = paypal_transaction["amount"]["value"]
        transaction.external_status = paypal_transaction["status"]
        create_attendee_for_register_form(transaction, register_form)
        return transaction.save
      else
        transaction.transaction_status_type = TransactionStatusType.failed
        transaction.external_status = response_json["status"]
        transaction.save
        return false
      end 
    end

    def create_attendee_for_register_form transaction, register_form
      attendee = Attendee.new(register_form.as_json(except: :id))
      attendee.save!
      transaction.attendee = attendee
    end

    def execute_refund transaction
      url = URI("#{base_url}/v2/payments/captures/#{transaction.external_transaction_id}/refund")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Prefer"] = "return=representation"
      request["Authorization"] = "Bearer #{token}"

      response = https.request(request)
      create_refund_transaction_record(transaction, response)
    end

    def create_refund_transaction_record transaction, response
      response_json = JSON.parse(response.read_body)
      refund_transaction = transaction.dup
      refund_transaction.external_payment_id = nil
      if response.code == "201"
        amount = response_json['seller_payable_breakdown']['total_refunded_amount']['value'].to_i * -1
        external_status = response_json['status'] == 'COMPLETED' ? 'REFUNDED' : response_json['status']
        refund_transaction.amount = amount
        refund_transaction.external_transaction_id = response_json['id']
        refund_transaction.external_status = external_status
        refund_transaction.save
      else
        refund_transaction.amount = 0
        refund_transaction.transaction_status_type = TransactionStatusType.failed
        refund_transaction.external_status = response_json['details'].to_s[0..244]
        refund_transaction.external_status = response_json['error'] if refund_transaction.external_status.blank?
        refund_transaction.save
        return false
      end
    end

    def create_attendee_for_register_form transaction, register_form
      attendee = Attendee.new(register_form.as_json(except: :id))
      attendee.save!
      transaction.attendee = attendee
    end

    def create_order_exhibitor(transaction, cart)

      url = URI("#{base_url}/v2/checkout/orders")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Prefer"] = "return=representation"
      # request["PayPal-Request-Id"] = "b4e9d187-a114-41ee-a6aa-be81b0cedc87"
      request["Authorization"] = "Bearer #{token}"

      items = []
      total = 0

      cart.cart_items.each do |item|
        if item.item_type == 'Product'
          items.push({
            "name": item.item.name,
            "quantity": item.quantity,
            "unit_amount": {
                        "currency_code": "USD",
                        "value": item.item.price.to_s 
                      }
          })
          total = total + (item.item.price * item.quantity )
        else  
          items.push({
            "name": item.item.products.first.name,
            "quantity": item.quantity,
            "unit_amount": {
                        "currency_code": "USD",
                        "value": item.item.products.first.price.to_s
                      }
          })
          total = total + (item.item.products.first.price * item.quantity)
        end
      end

      request.body = JSON.dump({
        "intent": "CAPTURE",
        "purchase_units": [
          {
            "items": items,
            "amount": {
              "currency_code": "USD",
              "value": total.to_s,
              "breakdown": {
                "item_total": {
                  "currency_code": "USD",
                  "value": total.to_s
                }
              }
            },
            "description":  "Payment for: #{cart.user.email}"
          }
        ]
      })

      response = https.request(request)
      response_json = JSON.parse(response.read_body)
      if response.code == "201"
        id = response_json["id"]
        status = response_json["status"]
        transaction.external_status = status
        transaction.external_payment_id = id
        return id if transaction.save
      else
        status = response_json["status"] || response_json["details"][0]["issue"] rescue nil || response_json["message"]
        transaction.external_status = status
        transaction.save
        return false
      end
    end

    def execute_payment_exhibitor(order_id, payer_id, transaction)
      url = URI("#{base_url}/v2/checkout/orders/#{order_id}/capture")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Prefer"] = "return=representation"
      # request["PayPal-Request-Id"] = "08fc4105-49a0-4a1a-892c-90aaa1eee5d4"
      request["Authorization"] = "Bearer #{token}"
      begin
        response = https.request(request)
        update_transaction_exhibitor(transaction, response, payer_id)
      rescue StandardError => e
        transaction.update(external_status: e.message)
      end
    end

    def update_transaction_exhibitor(transaction, response, payer_id)
      response_json = JSON.parse(response.read_body)
      if response.code == "201"
        transaction.transaction_status_type = TransactionStatusType.success
        paypal_transaction = response_json["purchase_units"][0]["payments"]["captures"][0]

        transaction.external_cust_id = payer_id
        transaction.external_transaction_id = paypal_transaction["id"]
        transaction.amount = paypal_transaction["amount"]["value"]
        transaction.external_status = paypal_transaction["status"]
        create_order_and_order_items(transaction)
        return transaction.save
      else
        transaction.transaction_status_type = TransactionStatusType.failed
        transaction.external_status = response_json["status"]
        transaction.save
        return false
      end 
    end

    def create_order_and_order_items(transaction)
      cart = transaction.cart
      cart.status = 'payment_success'
      cart.save
      cart.create_order(transaction)
    end
    
    class << self
      def create_order_id(transaction)
        object =  self.new(transaction.mode_of_payment)

        return false if object.token.blank?
        object.create_order(transaction)
      end

      def complete_order(order_id, payer_id, register_form)
        transaction = Transaction.find_by(external_payment_id: order_id)
        return false unless transaction

        event_id = register_form.event_id
        object = self.new(transaction.mode_of_payment)
        object.execute_payment(order_id, payer_id, transaction, register_form)
      end

      def refund_order transaction
        return false unless transaction
        return false if transaction.external_transaction_id.blank?

        begin
          object = self.new(transaction.mode_of_payment)
          object.execute_refund(transaction)
        rescue StandardError => e
          return false
        end
      end

      def create_order_id_for_exhibitor(transaction, cart)
        object =  self.new(transaction.mode_of_payment)
        return false if object.token.blank?
        object.create_order_exhibitor(transaction, cart)
      end

      def complete_order_for_exhibitor(order_id, payer_id)
        transaction = Transaction.find_by(external_payment_id: order_id)
        return false unless transaction

        begin
          object = self.new(transaction.mode_of_payment)
          object.execute_payment_exhibitor(order_id, payer_id, transaction)
        rescue StandardError => e
          transaction.update(external_status: e, transaction_status_type_id: TransactionStatusType.failed)
          false
        end

      end
    end
  end
end