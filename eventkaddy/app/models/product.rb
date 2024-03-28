class Product < ApplicationRecord
  SIZES = ["XS", "S", "M", "L", "XL"]
  before_create :set_available_quantity
	belongs_to :event
  belongs_to :product_category, :foreign_key => 'product_categories_id'
	belongs_to :event_file, :foreign_key => 'image_event_file_id', optional: true
  has_many :location_mapping_products
  has_many :location_mappings, :through => :location_mapping_products
  has_many :sponsor_level_type_products
  has_many :sponsor_level_types, :through => :sponsor_level_type_products
  has_many :coupons

	after_destroy :destroy_event_file
  validates :gl_code,  presence: true
	validates :price, numericality: { greater_than_or_equal_to: 0}
  validates :quantity, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :has_sizes, inclusion: { in: [true, false] }

  scope :registration_products, ->(event_id){where(event: event_id, product_category: ProductCategory.registration(event_id), deleted: false)}
  scope :product_for_category, ->(product_category_id, event_id) {where(event: event_id, product_categories_id: product_category_id, deleted: false)}

  attr_accessor :booth_for_additional_sponser

  def upload_image(image_file)
    target_path             = Rails.root.join('public','event_data', self.event_id.to_s, 'product').to_path
    event_file_type_id      = EventFileType.find_or_create_by(name: "product").id
    event_file              = EventFile.new(event_id:self.event_id, event_file_type_id:event_file_type_id)
    cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
    cloud_storage_type      = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             target_path,
      new_filename:            image_file.original_filename,
      cloud_storage_type:      cloud_storage_type
    ).call
    self.update_attribute("image_event_file_id", event_file.id)
  end

  def destroy_event_file
    self.event_file.mark_deleted if self.event_file
  end

  def set_available_quantity
    self.available_qantity = self.quantity
  end

  # checking the product to verify conditions
  # like deleted, startdate, enddate and available quantity.
  def is_product_available?
    !self.deleted && self.start_date.present? && self.start_date.to_time != self.end_date.to_time && self.start_date != nil && self.end_date != nil && (Time.now >= self.start_date.to_time && Time.now <= self.end_date.to_time) && self.available_qantity > 0
  end

  def available? quantity
    if self.is_product_available?
      if self.available_qantity.to_i >= quantity.to_i
        return true
      else
        return false
      end
    end
  end

end
