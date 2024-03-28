class CustomForm < ApplicationRecord
  
  belongs_to :event
  belongs_to    :custom_form_type

  serialize :json, JSON

end