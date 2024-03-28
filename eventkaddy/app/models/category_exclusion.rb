class CategoryExclusion < ApplicationRecord
  belongs_to :category, class_name: "ProductCategory", foreign_key: "category_id"
  belongs_to :excluded_category, class_name: "ProductCategory", foreign_key: "excluded_category_id"
end
