class SessionRecommendation < ApplicationRecord

  belongs_to :attendee
  belongs_to :recommendation_persistence_type
  belongs_to :recommendation_source_type
end
