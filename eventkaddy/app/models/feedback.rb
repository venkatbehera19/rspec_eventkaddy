class Feedback < ApplicationRecord
  # attr_accessible :attendee_id, :comment, :event_id, :rating, :session_id
  
  belongs_to :event
  belongs_to :attendee
  belongs_to :session

	def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |feedback|
        csv << feedback.attributes.values_at(*column_names)
      end
    end
  end

	  
end
