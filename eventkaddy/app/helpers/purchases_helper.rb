module PurchasesHelper

  def mode_of_payment_name mode_of_payment_id
    mode_of_payment = ModeOfPayment.find mode_of_payment_id
    mode_of_payment.name
  end

end
