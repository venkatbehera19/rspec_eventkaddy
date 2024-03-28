require 'rails_helper'

RSpec.describe CategoryExclusion do
  describe '::association' do
    it { should belong_to(:category).class_name("ProductCategory").with_foreign_key("category_id")}
    it { should belong_to(:excluded_category).class_name("ProductCategory").with_foreign_key("excluded_category_id")}
  end
end
