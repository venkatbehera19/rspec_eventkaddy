class Answer < ApplicationRecord
  belongs_to :event
  belongs_to :question
  belongs_to :answer_handler, optional: true
  has_many :responses, :dependent => :destroy
  # attr_accessible :answer, :correct, :order, :event_id, :question_id

  before_destroy :reorder_answers

  def reorder_answers
    Answer.where("question_id=#{question_id} AND answers.order>#{order}").each do |a|
      new_order = a.order - 1
      a.update!(order:new_order)
    end
  end

  def self.answers_as_array question_ids, responses, questions_type_ids
    i = -1
    question_ids.map do |q_id|
      i += 1
      rs = responses.select {|r| r.question_id == q_id }
      if rs.blank?
        ""
      elsif rs.first[:answer_id] # multiple choice or multiple select
        where(id: rs.map {|r| r[:answer_id]}).map(&:answer).join(', ')
      elsif questions_type_ids[i] == 4 && rs.first[:response] # for normailzed responses for multi-select
        ans_ids = rs.first[:response].split(',')
        where(id: ans_ids).map(&:answer).join(', ')
      elsif rs.first[:rating] # star rating
        rs.first[:rating]
      elsif rs.first[:response] # long form
        rs.first[:response] 
      end
    end
  end

  # this and the above function are really talking about responses,
  # but the Answer case requires us to do something special. For quizes,
  # we should only be interested in the answer case, but I'll leave the other
  # cases in for completeness in case of user error or a decision in the future
  # to extend the abilities of the quiz to accept other answers
  def self.quiz_answers_as_array question_ids, responses
    answer_result = ->(value, correct_count=0) do
      {value: value, correct_count:correct_count}
    end
    question_ids.map do |q_id|
      rs = responses.select {|r| r.question_id == q_id }
      if rs.blank?
        answer_result.call ""
      elsif rs.first[:answer_id] # multiple choice or multiple select
        r = where(id: rs.map {|r| r[:answer_id]})
        answer_result.call r.map(&:answer).join(', '), r.reduce(0) {|memo, a| memo + (a.correct ? 1 : 0)}
      elsif rs.first[:rating] # star rating
        answer_result.call rs.first[:rating]
      elsif rs.first[:response] # long form
        answer_result.call rs.first[:response]
      end
    end
  end
end
