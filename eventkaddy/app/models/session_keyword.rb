class SessionKeyword < ApplicationRecord
  belongs_to :session
  belongs_to :speaker, :foreign_key => 'speaker_id', :optional => true
end