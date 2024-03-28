class AvListItem < ApplicationRecord
  # attr_accessible :name
  
    has_many :session_av_requirements
    has_and_belongs_to_many :events, :join_table => :events_av_list_items


end
