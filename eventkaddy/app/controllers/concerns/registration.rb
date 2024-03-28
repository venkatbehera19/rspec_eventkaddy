module Registration
  extend ActiveSupport::Concern

  # it calculate the total amount for cart items
  def total_amount_member cart
    cart.registration_form_cart_items.reduce(0) do |sum, item|
      if item.item_type == 'Product'
        sum = sum + (item.item.member_price * item.quantity )
      else
        sum = sum + (item.item.products.first.member_price * item.quantity)
      end
      sum
    end
  end

  def total_amount_non_member cart
    cart.registration_form_cart_items.reduce(0) do |sum, item|
      if item.item_type == 'Product'
        sum = sum + (item.item.price * item.quantity )
      else
        sum = sum + (item.item.products.first.member_price * item.quantity)
      end
      sum
    end
  end

  def check_attendee_registration_product setting, order
    order_item_ids         = order.order_items.distinct.pluck('order_items.item_id')
    product_categories_ids = Product.where(id: order_item_ids).pluck('DISTINCT product_categories_id')
    registration_categories_ids = setting.registration_category_ids || []
    product_categories_ids.each do |category_id|
      if registration_categories_ids.include?(category_id.to_s)
        return true
      end
    end
    false
  end

  def remove_single_category_product cart, product
    cart_item = CartItem.find_by(
			item_id: product.id,
			item_type: product.class.name,
			cart_id: cart.id
		)
    cart_item.delete
    cart_item
  end

  def get_event_map product_category
    map_type        = MapType.find_by_map_type('Interactive Map')
    event_map       = EventMap.joins(location_mappings: :products).find_by(
      map_type_id: map_type.id, event_id: product_category.event_id
    )
    event_map
  end

  def get_deleted_location_mapping_with_product_associated product_category
    event_map = get_event_map(product_category)

    location_mapping_with_product_associated = event_map.location_mappings
		.joins(:location_mapping_products)
		.where(locked_by: nil, product_id: nil)
		.select{|booth|(
			booth.products.first.iid != 'premium_location'
		)}

    already_bought    = LocationMapping
		.joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id')
    .joins('LEFT JOIN orders ON order_items.order_id = orders.id')
		.where(order_items: {item_type: 'LocationMapping'}, orders: { status: 'paid'})
		.uniq

		already_booked_lm = Exhibitor
		.joins(:location_mapping)
		.where(event_id: product_category.event_id)
		.pluck(:'location_mappings.id')
		.uniq

    location_mapping_both      = LocationMapping.where(id: already_booked_lm)
    available_location_mapping = (location_mapping_with_product_associated - already_bought) - location_mapping_both
    available_location_mapping
  end

  def get_added_location_mapping_with_product_associated product_category
    event_map = get_event_map(product_category)

    if product_category.iid == 'sponsorship_with_booth_selection'
      location_mapping_with_product_associated = event_map.location_mappings
			.joins(:location_mapping_products)
			.where(locked_by: nil, product_id: nil)
			.select{|booth| booth.products.first.iid == 'premium_location' ||
        booth.products.first.iid == 'corner_booth' ||
        booth.products.first.iid == 'standard_in-line'
      }
    else
      location_mapping_with_product_associated = event_map.location_mappings
			.joins(:location_mapping_products)
			.where(locked_by: nil, product_id: nil)
			.select{|booth|(
				booth.products.first.iid != 'premium_location'
			)}
    end

    already_bought    = LocationMapping
    .joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id')
    .joins('LEFT JOIN orders ON order_items.order_id = orders.id')
    .where(order_items: {item_type: 'LocationMapping'}, orders: { status: 'paid'})
    .uniq
    already_booked_lm = Exhibitor
    .joins(:location_mapping)
    .where(event_id: product_category.event_id)
    .pluck(:'location_mappings.id')
    .uniq

    location_mapping_both      = LocationMapping.where(id: already_booked_lm)
    available_location_mapping = (location_mapping_with_product_associated - already_bought) - location_mapping_both
    available_location_mapping
  end

end
