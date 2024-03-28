class Cart < ApplicationRecord
	belongs_to :user
	has_many :cart_items, dependent: :destroy
  has_many :transactions
  has_many :discount_allocations, through: :cart_items
  STATUS = ['on_product_select_page', 'on_payment_page', 'payment_success']
  alias registration_form_cart_items cart_items
	def create_order(transaction)
		order = Order.create(user_id: self.user_id, transaction_id: transaction.id)
    total = 0
    self.cart_items.each do |item|
      if item.item_type == 'Product'
        discount_allocations = item.discount_allocations.last
        if item.item.product_category.iid == 'staff_members' && discount_allocations.present?
          order_item = OrderItem.create(
                        item_id: item.item_id,
                        item_type: item.item_type,
                        name: item.item.name,
                        quantity: item.quantity,
                        price: discount_allocations.amount,
                        order_id: order.id
                      )
          order_discount_allocation = DiscountAllocation.create(
                                        amount: discount_allocations.amount,
                                        complimentary_count: discount_allocations.complimentary_count,
                                        complimentary_amount: discount_allocations.complimentary_amount,
                                        discounted_count: discount_allocations.discounted_count,
                                        discounted_amount: discount_allocations.discounted_amount,
                                        full_count: discount_allocations.full_count,
                                        full_amount: discount_allocations.full_amount,
                                        user_id: discount_allocations.user_id,
                                        event_id: discount_allocations.event_id,
                                        order_item_id: order_item.id,
                                      )
          total = total + discount_allocations.amount
        else
          order.order_items.new(
                item_id: item.item_id,
                item_type: item.item_type,
                name: item.item.name,
                price: item.item.price,
                quantity: item.quantity
              )
          total = total + (item.item.price * item.quantity )
        end
      else
        if item.discount_allocations.present?
          discount_allocation_booth = item.discount_allocations.first
          order_item = OrderItem.create(
            item_id: item.item_id,
            item_type: item.item_type,
            name: item.item.products.first.name,
            price: discount_allocation_booth.amount,
            quantity: item.quantity,
            order_id: order.id
          )
          DiscountAllocation.create(
            amount: discount_allocation_booth.amount,
            full_count: discount_allocation_booth.full_count ,
            full_amount: discount_allocation_booth.full_amount,
            user_id: discount_allocation_booth.user_id,
            event_id: discount_allocation_booth.event_id,
            order_item_id: order_item.id,
          )
          total = total + discount_allocation_booth.amount
        else
          order.order_items.new(
            item_id: item.item_id,
            item_type: item.item_type,
            name: item.item.products.first.name,
            price: item.item.products.first.price,
            quantity: item.quantity
          )
          total = total + (item.item.products.first.price * item.quantity)
        end
      end
    end
    order.total = total
    order.status = "Pending"
    order.save
	end

  def is_single_category_product_available? product
    self.cart_items.each do |item|
      if item.item_id == product.id
        return true
      end
    end
    return false
  end

  # checking the category item present in cart or not
  def check_category_item_is_present_in_cart? category
    cart_items = self.cart_items.where(item_type: 'Product')
    cart_items.each do |cart_item|
      if cart_item.item.product_categories_id == category.id
        return true
      end
    end
    return false
  end

  # it returns the quantity in cart
  def cart_item_quantity_by_product product
    cart_item = self.cart_items.where( item_id: product.id)
    if cart_item.present?
      return cart_item.first.quantity
    else
      return 0
    end
  end

  def calculate_total_amount
    total = 0
    self.cart_items.each do |cart_item|
      if cart_item.item_type == 'Product'
        discount_allocations = cart_item.discount_allocations.last
        if cart_item.item.product_category.iid == 'staff_members' && discount_allocations.present?
          total = total + discount_allocations.amount
        else
          total = total + (cart_item.item.price * cart_item.quantity )
        end
      else
        if cart_item.discount_allocations.present?
          discount_allocation_booth = cart_item.discount_allocations.first
          total = total + discount_allocation_booth.amount
        else
          total = total + (cart_item.item.products.first.price * cart_item.quantity )
        end
      end
    end
    total
  end

  def calculate_total_amount_v2 sponsorship_with_booth_selection_category, category_ids, exhibitor = nil
    total = 0
    @maximum_complimentary_staff = 0
    @maximum_discount_staff      = 0
    location_mapping_cart_item   = cart_items.find_by(item_type: 'LocationMapping')
    product                      = location_mapping_cart_item&.item&.products&.first

    if product.present?
      @maximum_complimentary_staff = product.maximum_complimentary_staff || 0
      @maximum_discount_staff      = product.maximum_discount_staff || 0
    end

    if !exhibitor.nil? && exhibitor.staffs.present?
      if exhibitor.staffs["discount_staff_count"].present?
        @maximum_discount_staff += exhibitor.staffs["discount_staff_count"].to_i
      end
      if exhibitor.staffs["complimentary_staff_count"].present?
        @maximum_complimentary_staff += exhibitor.staffs["complimentary_staff_count"].to_i
      end
    end

    self.cart_items.each do |cart_item|
      if cart_item.item_type == 'LocationMapping'

        if sponsorship_with_booth_selection_category && category_ids.include?(sponsorship_with_booth_selection_category.id)
          discount_allocation_booth = DiscountAllocation.find_or_initialize_by(
						cart_item: cart_item,
						event_id: product.event_id,
						user_id: self.user_id
					)
					discount_allocation_booth.apply_discount_booth(cart_item.item.products.first.member_price)
					total = total + discount_allocation_booth.amount

        else
          discount_allocation_booth = DiscountAllocation.find_by(
						cart_item: cart_item,
						event_id: product.event_id,
						user_id: self.user_id
					)

          if discount_allocation_booth.present?
            discount_allocation_booth.delete
          end
          total += product.price.to_i
        end

      else
        if cart_item.item.product_category.iid == 'staff_members'
          if @maximum_discount_staff.to_i == 0
            discount_allocation = DiscountAllocation.find_by(
              cart_item: cart_item,
              event_id: cart_item.item.event_id,
              user_id: self.user_id
            )
            if discount_allocation.present?
              discount_allocation.delete
            end
            total = total + (cart_item.item.price * cart_item.quantity )
          else
            discount_allocation = DiscountAllocation.find_or_initialize_by(
              cart_item: cart_item,
              event_id: cart_item.item.event_id,
              user_id: self.user_id
            )
            discount_allocation.
              apply_discount(
                cart_item.quantity,
                @maximum_complimentary_staff,
                @maximum_discount_staff,
                cart_item.item.member_price,
                cart_item.item.price
              )
            total = total + discount_allocation.amount
          end
        else
          total = total + (cart_item.item.price * cart_item.quantity )
        end
      end
    end
    total
  end

  def total_cart_item_quantity
    self.cart_items.reduce(0){|sum, item| sum += item.quantity}
  end

  def is_exhibitor_user_product?
   product_category = ProductCategory.where(iid: 'exhibitor_user_booth').first
   cart_items.where(item_type: 'Product').each do |cart_item|
    if cart_item.item.product_categories_id == product_category.id
      return true
    end
   end
   return false
  end
end
