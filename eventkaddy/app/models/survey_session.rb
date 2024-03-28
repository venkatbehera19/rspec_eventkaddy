class SurveySession < ApplicationRecord

  belongs_to :survey
  belongs_to :session

end
