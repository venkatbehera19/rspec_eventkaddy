class ProductCategory < ApplicationRecord
  belongs_to :event
  has_many :products, foreign_key: "product_categories_id"
  # has_many :category_exclusions
  scope :for_event, ->(event_id) { where(event: event_id) }
  scope :registration, ->(event_id) {find_by(event: event_id, iid: 'registration')}
  Categories = ["Registration", "Exhibitor Booth", "Sponsor", "Sponsor Optional", "Staff Members", "Lead Retrieval"]

  def self.create_product_category event_id
    self::Categories.each do |name|
      product_category = self.find_by(iid: name.downcase.gsub(' ', '_'), event_id: event_id)
      if product_category.nil?
        self.create(name: name, iid: name.downcase.gsub(' ', '_'), event_id: event_id)
      end
    end
  end

  def is_single_select_product?
    self.single_product ? true : false
  end

  def is_multi_select_product?
    self.multi_select_product ? true : false
  end

end
