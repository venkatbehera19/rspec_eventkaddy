require 'rails_helper'

RSpec.describe Cart, type: :model do

  describe 'associations' do
    it { should belong_to(:user).class_name('User') }
    it { should have_many(:cart_items).dependent(:destroy) }
    it { should have_many(:transactions)}
    it { should have_many(:discount_allocations).through(:cart_items)}
  end

  describe 'constants' do
    it "defines STATUS constant" do
      expect(Cart::STATUS).to eq(['on_product_select_page', 'on_payment_page', 'payment_success'])
    end
  end

  describe "#calculate_total_amount" do
    # FactoryBot.define do
    #   factory :cart do
    #     association :user
    #     # Example of using Faker gem to generate random data
    #     status { 'on_product_select_page' }
    #   end
    # end

    let(:user) { create(:user) }
    let(:cart) { create(:cart, user: user) }
  end

  describe "#is_exhibitor_user_product?" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let(:event) { create(:event, org_id: organization.id)  }
    let(:exhibitor) { create(:exhibitor, event_id: event.id, user_id: user.id ) }
    let(:product_category) { create(:product_category, iid: 'exhibitor_user_booth', event: event) }

    context 'when the cart contains products of the specified category' do
      it 'returns true' do
        product = create(:product,
          product_categories_id: product_category.id,
          name: 'Testing 1',
          iid: 'testing_1',
          event_id: event.id,
          has_sizes: false,
          gl_code: 'jjksIkla',
          price: 100,
          member_price: 500,
          quantity: 1,
          start_date: Date.today - 2,
          end_date: Date.today + 7
        )
        # cart_item = create(:cart_item, cart: exhibitor.user.cart, item: product)

        # expect(exhibitor.is_exhibitor_user_product?).to be_truthy
      end
    end
  end


end
