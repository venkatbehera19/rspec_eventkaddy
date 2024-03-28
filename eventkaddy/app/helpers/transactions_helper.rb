module TransactionsHelper

  def check_able_to_buy_products(product, cart)
    if product.quantity == 0 || product.quantity == nil
      return true
    end
    category_exclusions = CategoryExclusion.where( excluded_category_id: product.product_category.id ).
    pluck(:category_id)
    category_exclusions_reverse = CategoryExclusion.where(category_id: product.product_category.id).
    pluck(:excluded_category_id)
    cart_items = cart.cart_items.where('item_type': 'Product')
    cart_items.each do |cart_item|
      is_present_in_category_exclusions = category_exclusions.include?(cart_item.item.product_categories_id) ||
                                          category_exclusions_reverse.include?(cart_item.item.product_categories_id)
      if is_present_in_category_exclusions == true
        return true
      end
    end
    return false
  end

  def sorted_location_mapping(available_location_mapping)
    location_mapping = available_location_mapping.sort_by do |item|
      [
        item.products.first.name,
        item.name[/\d+/].to_i,
        item.name
      ]
    end
    location_mapping
  end
end
