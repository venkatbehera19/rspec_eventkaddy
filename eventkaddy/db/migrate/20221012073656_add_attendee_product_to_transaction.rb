class AddAttendeeProductToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_reference :transactions, :attendee_product
    AttendeeProduct.where.not(transaction_id: nil).each do |record|
      transaction = Transaction.find_by_id(record.transaction_id)
      if transaction && transaction.attendee_product_id.nil?
        transaction.attendee_product_id = record.id
        transaction.save
      end
    end
  end
end

