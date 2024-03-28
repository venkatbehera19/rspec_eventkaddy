class DiscountAllocation < ApplicationRecord
  belongs_to :cart_item,  optional: true
  belongs_to :order_item, optional: true

  def apply_discount quantity, maximum_complimentary, maximum_discount, member_price, regular_price
    total_quantity = quantity
    total_discount_amount = 0
    maximum_discount = maximum_discount.to_i

    # if total_quantity >= maximum_complimentary
    #   update(
    #     complimentary_count: maximum_complimentary,
    #     complimentary_amount: 0
    #   )
    #   total_quantity -= maximum_complimentary
    # else
    #   update(
    #     complimentary_count: total_quantity,
    #     complimentary_amount: 0
    #   )
    #   total_quantity = 0
    # end

    if total_quantity >= maximum_discount && maximum_discount > 0
      discounted_amount = maximum_discount * member_price
      total_discount_amount = total_discount_amount + discounted_amount
      update(
        discounted_count: maximum_discount,
        discounted_amount: discounted_amount,
        amount: total_discount_amount
      )
      total_quantity -= maximum_discount
    else
      if maximum_discount > 0
        discounted_amount = total_quantity * member_price
        total_discount_amount = total_discount_amount + discounted_amount
        update(
          discounted_count: total_quantity,
          discounted_amount: discounted_amount,
          amount: total_discount_amount
        )
        total_quantity = 0
      end
    end

    if total_quantity > 0
      full_amount = total_quantity * regular_price
      total_discount_amount = total_discount_amount + full_amount
      update(
        full_count: total_quantity,
        full_amount: full_amount,
        amount: total_discount_amount
      )
    end
  end

  def apply_discount_booth price
    update( full_count: 1, full_amount: price, amount: price)
  end
end
