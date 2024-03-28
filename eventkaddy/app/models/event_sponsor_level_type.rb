class EventSponsorLevelType < ApplicationRecord
  belongs_to :event
  belongs_to :sponsor_level_type
  has_one :medal_image, as: :blob, class_name: 'FileAsset', dependent: :destroy

  before_create :set_rank

  def set_rank
    last_rank = EventSponsorLevelType.where(event_id: self.event_id).maximum(:rank)
    self.rank = last_rank ? last_rank + 1 : 0 
  end
end
