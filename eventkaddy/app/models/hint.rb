class Hint < ApplicationRecord
  belongs_to :event
  belongs_to :question

  # attr_accessible :hint, :order, :event_id, :question_id

  before_destroy :reorder_hints

  def reorder_hints
    Hint.where("question_id=#{question_id} AND hints.order>#{order}").each do |a|
      new_order = a.order - 1
      a.update!(order:new_order)
    end
  end

end
