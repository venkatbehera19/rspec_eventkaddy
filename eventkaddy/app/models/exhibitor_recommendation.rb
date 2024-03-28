class ExhibitorRecommendation < ApplicationRecord
  # attr_accessible :attendee_id, :event_id, :exhibitor_code, :exhibitor_id, :reason, :recommendation_persistence_type_id, :recommendation_source_type_id, :useful

  belongs_to :exhibitor
  belongs_to :recommendation_persistence_type
  belongs_to :recommendation_source_type
end
