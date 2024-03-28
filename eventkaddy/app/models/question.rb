class Question < ApplicationRecord
  belongs_to :event
  belongs_to :survey
  belongs_to :survey_section
  belongs_to :question_type
  has_many :answers, :dependent => :destroy
  has_many :hints, :dependent => :destroy


  before_destroy :reorder_questions

  def reorder_questions
    Question.where("survey_section_id=#{survey_section_id} AND questions.order>#{order}").each do |q|
      new_order = q.order - 1
      q.update!(order:new_order)
    end
  end
end
