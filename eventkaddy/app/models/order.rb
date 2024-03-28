class Order < ApplicationRecord
	belongs_to :user, optional: true
	belongs_to :registration_form, :foreign_key => 'registration_form_id', optional: true
	belongs_to :transaction_detail, foreign_key: "transaction_id", class_name: "Transaction", optional: true
	has_many :order_items, dependent: :destroy
	has_many :order_transactions, dependent: :destroy
	STATUS = ['pending', 'paid', 'failed', 'refund_intiated', 'refund_completed']

	def calculate_staff_from_products event_id, exhibitor = nil
		staffs = {
			discount_staff_count: 0,
			complimentary_staff_count: 0
		}
		staff_member      = ProductCategory.find_by(iid: "staff_members", event_id: event_id )
		location_mappings = order_items.where(item_type: "LocationMapping")

		location_mappings.each do |location|
			product_details = location.item.products.first
			staffs[:discount_staff_count]      += product_details.maximum_discount_staff if product_details.maximum_discount_staff
			staffs[:complimentary_staff_count] += product_details.maximum_complimentary_staff if product_details.maximum_complimentary_staff
		end

		if exhibitor.present? && exhibitor.staffs.present? && exhibitor.staffs["discount_staff_count"].present?
			staffs[:discount_staff_count] = exhibitor.staffs["discount_staff_count"].to_i
			staffs[:complimentary_staff_count] = exhibitor.staffs["complimentary_staff_count"].to_i
		end

		if staff_member.present?
			staff_category_id = staff_member.id
			products =  order_items.where(item_type: "Product")

			products.each do |product|
				if product.item.product_categories_id == staff_category_id
					discount_allocation = product.discount_allocations.first
					if discount_allocation.present?
						staffs[:discount_staff_count] -= discount_allocation.discounted_count if staffs[:discount_staff_count] >= discount_allocation.discounted_count
						staffs[:complimentary_staff_count] -= discount_allocation.complimentary_count if staffs[:complimentary_staff_count] >= discount_allocation.complimentary_count
					end
				end
			end
		end
		staffs
	end

	def calculate_total_order_amount_v2 sponsorship_with_booth_selection_category, category_ids, exhibitor = nil
    total = 0
    @maximum_complimentary_staff = 0
    @maximum_discount_staff      = 0
    location_mapping_cart_item   = order_items.find_by(item_type: 'LocationMapping')
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

    self.order_items.each do |cart_item|
      if cart_item.item_type == 'LocationMapping'

        if sponsorship_with_booth_selection_category && category_ids.include?(sponsorship_with_booth_selection_category.id)
          discount_allocation_booth = DiscountAllocation.find_by(
            order_item: cart_item,
						event_id: product.event_id,
						user_id: self.user_id
          )
          if discount_allocation_booth.present?
            total = total + discount_allocation_booth.amount
          else
            total += product.price.to_i
          end

        else
          discount_allocation_booth = DiscountAllocation.find_by(
						order_item: cart_item,
						event_id: product.event_id,
						user_id: self.user_id
					)

          if discount_allocation_booth.present?
            total = total + discount_allocation_booth.amount
          else
            total += product.price.to_i
          end
        end

      else
        if cart_item.item.product_category.iid == 'staff_members'
          if @maximum_discount_staff.to_i == 0
            discount_allocation = DiscountAllocation.find_by(
              order_item: cart_item,
              event_id: cart_item.item.event_id,
              user_id: self.user_id
            )
            if discount_allocation.present?
              total = total + discount_allocation.amount
            else
              total = total + (cart_item.item.price * cart_item.quantity )
            end
          else
            discount_allocation = DiscountAllocation.find_by(
              order_item: cart_item,
              event_id: cart_item.item.event_id,
              user_id: self.user_id
            )
            if discount_allocation.present?
              total = total + discount_allocation.amount
            else
              total = total + (cart_item.item.price * cart_item.quantity )
            end
          end
        else
          total = total + (cart_item.item.price * cart_item.quantity )
        end
      end
    end
    total
  end
end
