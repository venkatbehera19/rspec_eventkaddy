class BoothOwnerWorker
  include Sidekiq::Worker

  queue_as :exhibitor
  sidekiq_options retry: 0

  # if the itemm didn't get purchesed
  # on time then it will remove the locked_by and locked_at
  def perform booth_id
    booth = LocationMapping.find_by(id: booth_id)
    if booth.present?
      order_items = OrderItem.where(item_id: booth_id)
      if !order_items.present?
        booth.locked_by = nil
				booth.locked_at = nil
				booth.save
      end
    end
  end

end
