require 'rails_helper'

RSpec.describe Question do
  describe '::association' do
    it { should belong_to(:event)}
    it { should belong_to(:survey)}
  end

  describe "::reorder_survey_sections" do
    # it "reorders survey sections correctly before destroying" do
    #   survey_section = create(:survey_section)
    #   higher_order_section = create(:survey_section, survey: survey_section.survey, order: survey_section.order + 1)
    #   survey_section.destroy
    #   expect(higher_order_section.reload.order).to eq(survey_section.order)
    # end
  end

end
