# frozen_string_literal: true

class PopulateEventSponsorLevelType < ActiveRecord::Migration[6.1]
  def up
    Exhibitor.where("event_id is not NULL and sponsor_level_type_id is not NULL").each do |exhibitor|
      EventSponsorLevelType.where(event_id: exhibitor.event_id, sponsor_level_type_id: exhibitor.sponsor_level_type_id).first_or_create
    end
  end

  def down
    EventSponsorLevelType.delete_all
  end
end
