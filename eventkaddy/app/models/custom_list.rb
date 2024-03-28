class CustomList < ApplicationRecord
  # attr_accessible :custom_list_type_id, :description, :event_id, :home_button_id, :image_event_file_id, :name

  belongs_to :home_button
  belongs_to :custom_list_type
	belongs_to :event_file, :foreign_key => 'image_event_file_id', :class_name => "EventFile"

  has_many :custom_list_items, :dependent => :destroy

end
