class ExhibitorLink < ApplicationRecord
	
	belongs_to :exhibitor
	belongs_to :event_file
	
end
