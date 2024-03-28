class SurveyResponse < ApplicationRecord

  belongs_to :event
  belongs_to :attendee
  belongs_to :survey
  has_many :responses, :dependent => :destroy

  class << self
    def get_attendee_image_questions_and_responses event_id,attendee_id,filter_value
      filter_hash={"pending": 2,"verified":1,"rejected":0}
      filter_string="and 1=1"
      if filter_value!="all"
        filter_string="and responses.image_status=#{filter_hash[filter_value.to_sym]}"
      end
      joins(:survey,responses: [question: :question_type]).where("survey_responses.event_id = #{event_id} and survey_responses.attendee_id = #{attendee_id} and (responses.response is not null and responses.response != '' ) and question_types.name = 'Image Upload'"+filter_string).select("surveys.title,questions.question,responses.response,responses.id as response_id,responses.image_status,responses.created_at").order("responses.created_at DESC").as_json(except: :id)
    end

    def get_attendee_image_responses event_id,attendee_id
      joins(:survey,responses: [question: :question_type]).where("survey_responses.event_id = #{event_id} and survey_responses.attendee_id = #{attendee_id} and (responses.response is not null and responses.response != '' ) and question_types.name = 'Image Upload'").select("surveys.title as survey_title,survey_responses.survey_id, responses.question_id as question_id,questions.question as question_name,responses.response as event_file_id").order("responses.created_at DESC")
    end

    def get_survey_image_questions_and_responses event_id,survey_id,filter_value, attendee = nil
      filter_hash={"pending": 2,"verified":1,"rejected":0}
      filter_string="and 1=1"
      if filter_value!="all"
        filter_string="and responses.image_status=#{filter_hash[filter_value.to_sym]}"
      end
      attendee_search = " " + filter_string
      if attendee.length > 0
        attendee_search = " and (attendees.first_name like '%#{attendee}%' or attendees.last_name like '%#{attendee}%')"
      end
      joins(:survey,:attendee,responses: [question: :question_type]).where("survey_responses.event_id = #{event_id} and survey_responses.survey_id = #{survey_id} and (responses.response is not null and responses.response != '' ) and question_types.name = 'Image Upload'"+filter_string+attendee_search).select("surveys.title,questions.question,responses.response,responses.id as response_id, responses.created_at, attendees.first_name, attendees.last_name, responses.image_status").order("responses.created_at DESC").as_json(except: :id)
    end

    def get_survey_image_responses event_id,survey_id
      joins(:survey,:attendee,responses: [question: :question_type]).where("survey_responses.event_id = #{event_id} and survey_responses.survey_id = #{survey_id} and (responses.response is not null and responses.response != '' ) and question_types.name = 'Image Upload'").select("surveys.title as survey_title,survey_responses.survey_id, responses.question_id as question_id,questions.question as question_name,responses.response as event_file_id, attendees.first_name, attendees.last_name").order("responses.created_at DESC")
    end

  end

end