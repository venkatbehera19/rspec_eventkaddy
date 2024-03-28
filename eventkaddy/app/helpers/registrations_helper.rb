module RegistrationsHelper
  def check_product (product, cart)
    quantity = 0;
    cart.registration_form_cart_items.each do |item| 
      if item.item_id == product.id 
        quantity = item.quantity
      end
    end
    quantity
  end

  def single_category_check_product product, cart
    cart.registration_form_cart_items.each do |item|
      if item.item_id == product.id
        return true
      end
    end
    false
  end

  def check_quantity (product, cart = nil)
    if current_user.present?
      if product.product_category.single_product
        unique_product_ids = current_user.orders
                                         .where(status: 'paid')
                                         .joins(:order_items)
                                         .distinct
                                         .pluck('order_items.item_id')
        uniq_product_category_ids = Product.where(id: unique_product_ids)
                                           .pluck('DISTINCT product_categories_id')

        if uniq_product_category_ids.include?(product.product_category.id)
          return true
        end

        category_exclusions = CategoryExclusion
                              .where(excluded_category_id: uniq_product_category_ids)
                              .pluck(:category_id)
        rev_category_exclusions = CategoryExclusion
                                  .where(category_id: uniq_product_category_ids)
                                  .pluck(:excluded_category_id)
        if (category_exclusions.include?(product.product_category.id) || rev_category_exclusions.include?(product.product_category.id) )
          return true
        end

      else
        unique_product_ids = current_user.orders
                                         .where(status: 'paid')
                                         .joins(:order_items)
                                         .distinct
                                         .pluck('order_items.item_id')
        uniq_product_category_ids = Product.where(id: unique_product_ids)
                                           .pluck('DISTINCT product_categories_id')

        category_exclusions = CategoryExclusion
                              .where(excluded_category_id: uniq_product_category_ids)
                              .pluck(:category_id)
        rev_category_exclusions = CategoryExclusion
                                  .where(category_id: uniq_product_category_ids)
                                  .pluck(:excluded_category_id)
        if (category_exclusions.include?(product.product_category.id) || rev_category_exclusions.include?(product.product_category.id) )
          return true
        end
      end
    end

    if cart.present?
      if product.quantity == 0 || product.quantity == nil
        return true
      end
      product_category = product.product_category
      category_exclusions = CategoryExclusion
      .where(excluded_category_id: product.product_category.id)
      .pluck(:category_id)
      category_exclusions_reverse = CategoryExclusion
      .where(category_id: product.product_category.id)
      .pluck(:excluded_category_id)
      cart.registration_form_cart_items.each do |cart_item|
        is_present_in_category_exclusions =  category_exclusions.include?(cart_item.item.product_categories_id) || category_exclusions_reverse.include?(cart_item.item.product_categories_id)
        if is_present_in_category_exclusions == true
          return true
        end
      end
      return false
    else
      if product.quantity == 0 || product.quantity == nil
        true
      else
        false
      end
    end
  end

  def list_category category
    category_exclusions = CategoryExclusion
      .where(excluded_category_id: category.id)
    category_exclusions_reverse = CategoryExclusion
      .where(category_id: category.id)
      if category_exclusions.present?
        category_name = []
        category_exclusions.each do |category_exclusion|
          category_name.push(category_exclusion.category.name)
        end
        # binding.pry
      return category_name.join(",")
    end
    if category_exclusions_reverse.present?
      category_name = []
      category_exclusions_reverse.each do |category_exclusion|
        category_name.push(category_exclusion.excluded_category.name)
      end
      # binding.pry
      return category_name.join(",")
    end
  end

end
