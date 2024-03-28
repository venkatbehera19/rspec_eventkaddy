class Option < ApplicationRecord
  validates :text, presence: true
  belongs_to :poll
end
