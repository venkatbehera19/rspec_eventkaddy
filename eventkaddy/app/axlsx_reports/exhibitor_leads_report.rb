
class ExhibitorLeadsReport < AxlsxReport

  attr_reader :event_id, :questions

  def initialize event_id, package, job=nil
    @event_id = event_id
    super package, job, event_id

    add_sheet "Exhibitor Lead Report", [ heads ].concat( data )
  end

  def heads
    [
      "Booth Name", "Rep Name", # name of the exhibitor attendee who filled out the survey
      "Booth Number", # location
      "Last Name", "First Name", # this is the name of the attendee who was scanned... the lead. so all the surveys they did are in one cell
      "Company", "Title", "Email", "Address", "City", "State", "Zip", # custom_filter_1 for the event in question
      "Country", "Business Phone", "Mobile Phone", "Account Code", "Created", "Updated" ].
      concat( questions.map {|q| "#{q.title} #{q.question}"} )
  end

  def questions
    @questions ||= Question.find_by_sql(["
    SELECT s.title AS title, q.question AS question, s.id AS survey_id, q.order AS question_order, ss.order AS section_order
    FROM questions AS q
    LEFT JOIN surveys          AS s  ON s.id                = q.survey_id
    LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
    WHERE q.event_id = ? AND s.survey_type_id = 6", event_id])
  end

  def data
    responses.map {|r|
      row = [
        r[:company_name],
        r[:rep_name],
        r[:location_name], # booth number
        r[:lead_last_name],
        r[:lead_first_name],
        r[:lead_company],
        r[:lead_title],
        r[:lead_email],
        r[:lead_address],
        r[:lead_city],
        r[:lead_state],
        r[:lead_zip],
        r[:lead_country],
        r[:lead_business_phone],
        r[:lead_mobile_phone],
        r[:lead_account_code],
        r[:response_created].strftime('%D %r'),
        r[:response_updated].strftime('%D %r')
      ].concat(
        questions.map {|q|
          # this didn't work
          r.responses_for(q.survey_id, q.section_order, q.question_order).map {|r| 
            if r[:question_type_id] == 4 && !r[:answer_id].blank?
              ans_ids = r[:response].split(',')
              res = Answer.where(id: ans_ids).map(&:answer).join(', ')
              encode res
            else
              encode r[:response]
            end
          }.join("\r\r")
        }
      )
    }
  end

  def responses
    result = Response.find_by_sql([
      "SELECT s.title,
              s.id AS survey_id,
              ss.heading,
              ss.subheading,
              ta.id AS target_attendee_id,
              ta.iattend_sessions,
              at.account_code,
              CONCAT(at.first_name, ' ', at.last_name) AS rep_name,
              e.company_name,
              lm.name AS location_name,
              ta.first_name AS lead_first_name,
              ta.last_name AS lead_last_name,
              ta.company AS lead_company,
              ta.email AS lead_email,
              ta.business_phone AS lead_business_phone,
              ta.mobile_phone AS lead_mobile_phone,
              ta.iattend_sessions AS lead_iattend_sessions,
              ta.title AS lead_title,
              ta.city AS lead_city,
              ta.state AS lead_state,
              ta.country AS lead_country,
              ta.account_code AS lead_account_code,
              ta.custom_filter_1 AS lead_zip,
              sr.created_at AS response_created,
              sr.updated_at AS response_updated,
              GROUP_CONCAT(
                  CONCAT( s.id, '^^', ss.order, '^^', q.order, '^^', q.question_type_id, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) SEPARATOR '||'
              ) AS survey_answers,
              s.survey_type_id
      FROM responses AS r
      LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
      LEFT JOIN questions        AS q  ON q.id                = r.question_id
      LEFT JOIN answers          AS a  ON a.id                = r.answer_id
      LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id # this is the exhibitor making the survey
      LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id # this is the person the survey is about...
      LEFT JOIN booth_owners     AS bo ON at.id               = bo.attendee_id
      LEFT JOIN exhibitors       AS e  ON e.id                = bo.exhibitor_id
      LEFT JOIN location_mappings AS lm ON e.location_mapping_id = lm.id
      WHERE r.event_id=? AND survey_type_id=6 AND sr.target_attendee_id IS NOT NULL
      GROUP BY sr.id
      ORDER BY e.company_name, at.last_name, s.id, sr.created_at, at.account_code, ss.order, q.order, a.order ", event_id ]).
    each {|r|
      r.survey_answers = (r.survey_answers || '').
        split('||').
        map {|r|
          parts = r.split('^^')
          {
            survey_id:        parts[0],
            section:          parts[1],
            question:         parts[2],
            question_type_id: parts[3],
            response:         parts[4]
          }
        }

      def r.responses_for survey_id, section_order, question_order
        survey_answers.select {|r| r[:survey_id].to_i == survey_id && r[:section].to_i == section_order && r[:question].to_i == question_order }
      end
    }
    result
  end

end
