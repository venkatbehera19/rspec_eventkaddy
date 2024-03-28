class QrCode < ApplicationRecord
  
  belongs_to :exhibitor_product
  belongs_to :event_file, :dependent => :destroy, :optional => true
  belongs_to :event

end
