require 'rails_helper'

RSpec.describe ProgramType do
  describe '::association' do
    it { should have_many(:sessions)}
  end
end
