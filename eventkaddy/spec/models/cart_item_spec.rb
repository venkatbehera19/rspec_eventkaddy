require 'rails_helper'

RSpec.describe CartItem, type: :model do

  describe 'associations' do
    it { should belong_to(:cart).class_name('Cart') }
    it { should belong_to(:item) }

    it { should have_many(:discount_allocations).dependent(:nullify)}
  end

end
