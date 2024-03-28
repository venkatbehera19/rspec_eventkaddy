class EventsAvListItem < ApplicationRecord
  # attr_accessible :av_list_item_id, :event_id

  belongs_to :event
  belongs_to :av_list_item

end
