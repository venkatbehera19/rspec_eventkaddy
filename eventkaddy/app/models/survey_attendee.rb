# this class was an accident, when thinking about exhibitor lead surveys
# we use SurveyExhibitor instead, though this may one day be useful
class SurveyAttendee < ApplicationRecord

  belongs_to :survey
  belongs_to :attendee
end
