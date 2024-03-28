class SurveySection < ApplicationRecord

  belongs_to :event
  belongs_to :survey

  has_many :questions, :dependent => :destroy

  before_destroy :reorder_survey_sections

  def reorder_survey_sections
    SurveySection.where("survey_id=#{survey_id} AND survey_sections.order>#{order}").each do |s_s|
      new_order = s_s.order - 1
      s_s.update!(order:new_order)
    end
  end

  def updateQuestionPositions(json)
    json = JSON.parse(json)
    json.each do |item|
      Question.find(item["id"].to_i).update!(order:item["order"])
    end
  end

end
