class Link < ApplicationRecord

	belongs_to :link_type
	belongs_to :event_file	
	
end
