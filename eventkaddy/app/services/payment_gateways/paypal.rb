module PaymentGateways
  class Paypal
    
    def initialize(payment_gateway)
      return '' if payment_gateway.blank?

      PayPal::SDK.configure(
        mode: payment_gateway.environment,
        client_id: payment_gateway.client_key,
        client_secret: payment_gateway.client_secret_key,
      )
    end

    def get_token(transaction)
      product  = transaction.product
      payment_price = product.price.to_s
      currency = "USD"
      payment = PayPal::SDK::REST::Payment.new({
        intent:  "sale",
        payer:  {
          payment_method: "paypal" },
        redirect_urls: {
          return_url: "/",
          cancel_url: "/" },
        transactions:  [{
          item_list: {
            items: [{
              name: product.name,
              sku: product.iid,
              price: payment_price,
              currency: currency,
              quantity: 1 }
              ]
            },
          amount:  {
            total: payment_price,
            currency: currency
          },
          description:  "Payment for: #{product.name} by Attendee : #{transaction.attendee_id}"
        }]
      })
      begin
        payment.create
        if payment.create
          transaction.external_payment_id = payment.id
          return payment.token if transaction.save
        end
      rescue StandardError => e
        transaction.external_status = e.message[0,240]
        transaction.save
        return false
      end
    end

    def execute_payment(payment_id, payer_id, transaction)
      payment = PayPal::SDK::REST::Payment.find(payment_id)
      if payment.execute( payer_id: payer_id )
        transaction.transaction_status_type = TransactionStatusType.success
        paypal_transaction = payment.transactions[0]
        sale = paypal_transaction.related_resources[0].sale

        transaction.external_cust_id = payer_id
        transaction.external_transaction_id = sale.id
        transaction.amount = paypal_transaction.amount.total
        transaction.external_status = sale.state
        return transaction.save
      end
    end
    
    class << self
      def create_payment_token(transaction)
        object = self.new(transaction.mode_of_payment)

        return false if object.blank?
        object.get_token(transaction)
      end

      def make_payment(payment_id, payer_id)
        transaction = Transaction.find_by(external_payment_id: payment_id)
        return false unless transaction

        event_id = transaction.attendee.event_id
        object = self.new(transaction.mode_of_payment)
        object.execute_payment(payment_id, payer_id, transaction)

      end
    end
  end
end