require 'rails_helper'

RSpec.describe Product do

  describe "association" do
    it { should belong_to(:event)}
    it { should belong_to(:product_category)}
    it { should belong_to(:event_file).with_foreign_key('image_event_file_id').optional(true)}

    it { should have_many(:location_mapping_products)}
    it { should have_many(:location_mappings).through(:location_mapping_products)}
    it { should have_many(:sponsor_level_type_products)}
    it { should have_many(:sponsor_level_types).through(:sponsor_level_type_products)}
    it { should have_many(:coupons)}
  end

  describe 'Constants' do
    it "defines Size constant" do
      expect(Product::SIZES).to eq(["XS", "S", "M", "L", "XL"])
    end
  end

  describe 'validations' do

    it "validates presence of gl_code" do
      should validate_presence_of(:gl_code)
    end

    it "validates presence of quantity" do
      should validate_presence_of(:quantity)
    end

    it "validates presence of start_date" do
      should validate_presence_of(:start_date)
    end

    it "validates presence of end_date" do
      should validate_presence_of(:end_date)
    end

    let(:product_category) { create(:product_category)}
    let(:event) { create(:event)}

    it 'price is numerical and greater than or equal to 0' do
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
      expect(product).to be_valid
      product.price = -5
      expect(product).not_to be_valid
      product.price = 'abc'
      expect(product).not_to be_valid

    end

    it 'validates inclusion of has_sizes attribute' do
      product = create(:product,
        product_categories_id: product_category.id,
        name: 'Testing 2',
        iid: 'testing_2',
        event_id: event.id,
        has_sizes: true,
        gl_code: 'jjksIkla',
        price: 100,
        member_price: 500,
        quantity: 1,
        start_date: Date.today - 2,
        end_date: Date.today + 7
      )

      expect(product).to be_valid

      product.has_sizes = false
      expect(product).to be_valid

      product.has_sizes = nil
      expect(product).not_to be_valid
      expect(product.errors[:has_sizes]).to include("is not included in the list")

    end

  end

  describe '::Scopes' do
    describe '::product_for_category' do
      let(:event) { create(:event) }
      let(:category) { create(:product_category) }

      it "returns products belonging to the specified event and category" do
        product1 = create(:product, event_id: event.id, product_categories_id: category.id, deleted: false, price: 20)
        product2 = create(:product, event_id: event.id, product_categories_id: category.id, deleted: false, price: 20)

        products = Product.product_for_category(category.id, event.id)
        expect(products).to include(product1, product2)

      end
    end
  end

  describe '::methods' do
    let(:event) { create(:event) }
    let(:category) { create(:product_category) }
    it "sets available_quantity to quantity" do
      product = build(:product, event_id: event.id, product_categories_id: category.id, deleted: false, price: 20, quantity: 10)
      product.save
      expect(product.available_qantity).to eq(10)
    end
    it "returns true if the product is available to buy" do
      product = build(:product, deleted: false, start_date: Date.yesterday, end_date: Date.tomorrow, quantity: 1, event_id: event.id, product_categories_id: category.id, price: 100)
      product.save
      expect(product.is_product_available?).to eq(true)
    end
    it "returns true" do
      product = build(:product, quantity: 10, deleted: false, start_date: Date.yesterday, end_date: Date.tomorrow, event_id: event.id, product_categories_id: category.id, price: 100)
      product.save
      expect(product.available?(5)).to eq(true)
    end
  end

end
