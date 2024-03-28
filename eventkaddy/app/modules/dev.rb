# some shortcuts for making test data and such, when current events do not have
# appropriate data to test with
module Dev


  def self.local_database?
    Rails.configuration.database_configuration[ Rails.env ][ "database" ] == 'stable_copy'
  end

  # idea: vim shortcut to run special test buffer... visual select the whole buffer + GM... open if not already up in sp

  # Dev.generate_survey_response 156, 276736, 285252
  # Attendee.where(event_id:20).where('company IS NOT NULL').each do |a|; Dev.generate_survey_response 156, a.id, lead.id; end
  # lead = Attendee.where(event_id:20, company:nil)[0]
  # Attendee.where(event_id:20).where('company IS NOT NULL').each do |a|; Dev.generate_survey_response 276, a.id, lead.id; end
  # Exhibitor.where(event_id:20).sample(20).each do |e|; Attendee.where(event_id:20, company:nil).first.update!(company: e.company_name); end
  #
  # actually what I wanted here was to generate a few attendees each being surveys by multiple exhibitors. oops
  def self.generate_survey_response survey_id, attendee_id, target_attendee_id
    survey = Survey.find survey_id
    attendee = Attendee.find attendee_id
    lead_attendee = Attendee.find target_attendee_id
    # ModelInfo.hash_for_model SurveyResponse # "{ id: integer, event_id: integer, attendee_id: integer, attendee_account_code: string, target_attendee_id: integer, session_id: integer, survey_id: integer, gps_location: integer, time_taken: integer, created_at: datetime, updated_at: datetime }"

    sr = SurveyResponse.where(
      event_id:              survey.event_id,
      attendee_id:           attendee_id,
      attendee_account_code: attendee.account_code,
      target_attendee_id:    target_attendee_id,
      survey_id:             survey.id,
    ).first_or_create

    # want to return here if it already exists, or we'll be overwriting resposnes

    survey.questions.each do |q|

      # ModelInfo.hash_for_model Response # "{ id: integer, event_id: integer, survey_response_id: integer, question_id: integer, answer_id: integer, response: text, rating: integer, created_at: datetime, updated_at: datetime }"

      case q.question_type.name
      when 'Multiple Choice'
        Response.create({
          event_id:           survey.event_id,
          survey_response_id: sr.id,
          question_id:        q.id,
          answer_id:          q.answers.sample.id,
          response:           nil,
          rating:             nil
        })
      when 'Long Form'
        Response.create({
          event_id:           survey.event_id,
          survey_response_id: sr.id,
          question_id:        q.id,
          answer_id:          nil,
          response:           "long form answer #{('a'..'z').to_a.shuffle[0,8].join}",
          rating:             nil
        })
      when 'Star Rating'
        Response.create({
          event_id:           survey.event_id,
          survey_response_id: sr.id,
          question_id:        q.id,
          answer_id:          nil,
          response:           nil,
          rating:             (0..5).to_a.sample
        })
      when 'Multiple Select'
        # how does this work again? Creates multiple with same q id?
        q.answers.sample(2).each do |a|
          Response.create({
            event_id:           survey.event_id,
            survey_response_id: sr.id,
            question_id:        q.id,
            answer_id:          a.id,
            response:           nil,
            rating:             nil
          })
        end
      when 'Autocomplete Exhibitor'
        Response.create({
          event_id:           survey.event_id,
          survey_response_id: sr.id,
          question_id:        q.id,
          answer_id:          nil,
          response:           Exhibitor.where(event_id:event_id).sample.company_name,
          rating:             nil
        })
      end

    end
  end

end
