# frozen_string_literal: true

class AddPaymentFor319Event < ActiveRecord::Migration[6.1]
  def up
    ['Stripe', 'Paypal', 'Affinipay'].each do |payment|
      ModeOfPayment.create(name: payment, event_id: 319, iid: payment.downcase)
    end
  end

  def down
    begin
      ['Stripe', 'Paypal', 'Affinipay'].each do |payment|
        ModeOfPayment.find_by(name: payment, event_id: 319, iid: payment.downcase).delete
      end
    rescue
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
