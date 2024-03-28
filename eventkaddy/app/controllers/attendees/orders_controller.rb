module Attendees
  class OrdersController < ApplicationController
    layout :set_layout

    before_action :get_settings, only: [:index]

    def index

    end

    def create
      cart = current_user.cart
      user = current_user
      is_product_not_avaialbale = false;
      notice = ""
      # binding.pry
      cart.cart_items.each do |cart_items|
        order_items_quantity = OrderItem.joins(:order).where(item_id: cart_items.item).where(orders: {status: ['paid', 'pending']}).length
        available_product_quantity = cart_items.item.quantity
        available_quantity = available_product_quantity - order_items_quantity
        if available_quantity <= 0
          is_product_not_avaialbale = true;
          notice = " product is unavailable. please remove #{cart_items.item.name} from cart"
          break;
        else
          puts "avilable products #{available_quantity}"
        end
      end
      order = user.create_order_for_attendee
      DeleteOrderForAttendeeWorker.perform_in(600, order.id)

      if is_product_not_avaialbale
        redirect_to attendees_cart_items_path, alert: notice
      else
        redirect_to new_attendees_order_payment_path(order.id)
      end
    end

    private
    def get_settings
      @settings = Setting.return_cached_settings_for_registration_portal({ event_id: current_user.attendee.event_id })
    end

    def set_layout
      @current_user = current_user
      if current_user.role? :attendee then
        'attendeeportal'
      else
        'subevent_2013'
      end
    end

  end
end
