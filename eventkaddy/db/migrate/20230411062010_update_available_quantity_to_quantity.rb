class UpdateAvailableQuantityToQuantity < ActiveRecord::Migration[6.1]
  def change
    Product.all.each do |prod|
      prod.update_column(:available_qantity, prod.quantity)
    end
  end
end
