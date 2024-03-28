require 'rails_helper'

RSpec.describe ProductCategory, type: :model do

  describe 'associations' do
    it { should belong_to(:event) }
    it { should have_many(:products) }
  end

  describe 'constants' do
    it "defines Categories constant" do
      expect(ProductCategory::Categories).to eq(["Registration", "Exhibitor Booth", "Sponsor", "Sponsor Optional", "Staff Members", "Lead Retrieval"])
    end
  end

  describe 'scopes' do
    describe 'for_event' do
      let!(:event1) { create(:event) }
      let!(:event2) { create(:event) }

      let!(:category1) { create(:product_category, event: event1)}
      let!(:category2) { create(:product_category, event: event2)}

      it 'returns product categories 1 for a specific event1' do
        expect(ProductCategory.for_event(event1.id)).to contain_exactly(category1)
      end

      it 'returns product categories 2 for a specific event2' do
        expect(ProductCategory.for_event(event2.id)).to contain_exactly(category2)
      end
    end

    describe 'registration' do
      let!(:event) { create(:event) }
      let!(:registration_category) { create(:product_category, event: event, iid: 'registration') }
      let!(:other_category) { create(:product_category, event: event) }

      it "returns the registration product category for a specific event" do
        expect(ProductCategory.registration(event.id)).to eq(registration_category)
      end

    end
  end

  describe "#is_single_select_product?" do
    let!(:event) { create(:event) }
    let!(:product_category) { create(:product_category, single_product: true, event: event)}

    it "returns true if the product category is single select" do
      expect(product_category.is_single_select_product?).to be_truthy
    end

    it "returns false if the product category is not single select" do
      product_category.update(single_product: false)
      expect(product_category.is_single_select_product?).to be_falsy
    end
  end

  describe "#is_multi_select_product?" do
    let!(:event) { create(:event) }
    let!(:product_category) { create(:product_category, multi_select_product: true, event: event)}

    it "returns true if the product category is single select" do
      expect(product_category.is_multi_select_product?).to be_truthy
    end

    it "returns false if the product category is not multi select" do
      product_category.update(multi_select_product: false)
      expect(product_category.is_multi_select_product?).to be_falsy
    end
  end

  describe "#create_product_category" do
    let!(:event) { create(:event) }

    it "creates product categories for the event" do
      expect {
        ProductCategory.create_product_category(event.id)
      }.to change { ProductCategory.count }.by(ProductCategory::Categories.count)
    end

    it "does not create duplicate product categories" do
      create(:product_category, event: event, iid: 'registration')

      expect {
        ProductCategory.create_product_category(event.id)
      }.to change { ProductCategory.count }.by(ProductCategory::Categories.count - 1)
    end
  end

end
