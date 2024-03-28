require 'rails_helper'

RSpec.describe Survey do
  describe '::association' do
    it { should belong_to(:survey_type)}
    it { should belong_to(:event)}
    it { should have_many(:survey_sessions).dependent(:destroy)}
    it { should have_many(:sessions).through(:survey_sessions)}
    it { should have_many(:survey_exhibitors).dependent(:destroy)}
    it { should have_many(:survey_sections).dependent(:destroy)}
    it { should have_one(:survey_ce_certificate).dependent(:destroy)}
    it { should have_many(:questions)}
    it { should have_many(:survey_responses).dependent(:destroy)}
  end

  describe '#update_json' do
    let(:survey) { create(:survey) }
    it 'updates the json attribute' do
      allow_any_instance_of(HashifySurvey).to receive(:call).and_return({ 'status' => true, 'survey' => { 'some_attribute' => 'some_value' } })
      survey.update_json
      expect(survey.reload.json).to eq({ 'some_attribute' => 'some_value' }.to_json)
    end
  end

  describe '#copy_to_event' do
    let(:event) { create(:event) }
    let(:survey) { create(:survey)}

    it 'copy the event and update the JSON' do
      schema_data = { ids: { event_id: event.id }, model: survey, columns: :all, children: [] }
      allow(MonkeySeeMonkeyDo).to receive(:copy_model_to_event).with(schema_data).and_return({ model: survey })
      allow(MonkeySeeMonkeyDo).to receive(:save_result_copy).and_return({ model: survey })

      result = survey.copy_to_event(event.id)
      expect(result[:model]).to eq(survey)

    end
  end

  describe '#schema' do
    let(:event) { create(:event) }
    let(:survey) { create(:survey) }
    it 'design a schema correctly' do
      survey_section1 = create(:survey_section, survey: survey)
      question1 = create(:question, survey_section: survey_section1)
      answer1 = create(:answer, question: question1)
      hint1 = create(:hint, question: question1)

      allow(survey).to receive(:survey_sections).and_return([survey_section1])
      allow(survey_section1).to receive(:questions).and_return([question1])
      allow(question1).to receive(:answers).and_return([answer1])
      allow(question1).to receive(:hints).and_return([hint1])

      schema = survey.schema(event.id)

      expect(schema[:ids][:event_id]).to eq(event.id)
      expect(schema[:model]).to eq(survey)
      expect(schema[:columns]).to eq(:all)

      expect(schema[:children].count).to eq(1)
      expect(schema[:children][0][:model]).to eq(survey_section1)

      expect(schema[:children][0][:children].count).to eq(1)
      expect(schema[:children][0][:children][0][:model]).to eq(question1)

      expect(schema[:children][0][:children][0][:children].count).to eq(2)
      expect(schema[:children][0][:children][0][:children][0][:model]).to eq(answer1)
      expect(schema[:children][0][:children][0][:children][1][:model]).to eq(hint1)

    end
  end

end
