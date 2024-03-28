require 'rails_helper'

RSpec.describe QrCode do
  describe '::association' do
    it { should belong_to(:exhibitor_product)}
    it { should belong_to(:event_file).dependent(:destroy).optional(true)}
    it { should belong_to(:event)}
  end
end
