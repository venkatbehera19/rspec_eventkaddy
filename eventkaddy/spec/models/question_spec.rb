require 'rails_helper'

RSpec.describe Question do
  describe '::association' do
    it { should belong_to(:event)}
    it { should belong_to(:survey)}
    it { should belong_to(:survey_section)}
    it { should belong_to(:question_type)}
    it { should have_many(:answers).dependent(:destroy)}
    it { should have_many(:hints).dependent(:destroy)}
  end
end
