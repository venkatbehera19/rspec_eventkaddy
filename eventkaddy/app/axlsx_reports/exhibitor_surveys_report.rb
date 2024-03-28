
class ExhibitorSurveysReport < AxlsxReport

  attr_reader :event_id, :exhibitor_id, :questions

  def initialize event_id, exhibitor_id, package, job=nil
    @exhibitor_id = exhibitor_id
    @event_id = event_id
    super package, job, event_id

    add_sheet "Exhibitor Surveys Report", [ heads ].concat( data )
  end

  def heads
    [
      "Survey Name","Heading","Subheading", "Exhibitor", "First Name", "Last Name", "Company Name", "Title",
       "City", "State", "Country", "Created", "Updated" ].
      concat( questions.map {|q| "#{q.title} #{q.question}"} )
  end

  def questions
    @questions ||= Question.find_by_sql(["
    SELECT s.title AS title, q.question AS question, s.id AS survey_id, q.order AS question_order, ss.order AS section_order
    FROM questions AS q
    LEFT JOIN surveys          AS s  ON s.id                = q.survey_id
    LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
    LEFT JOIN survey_exhibitors AS se ON se.survey_id       = s.id
    WHERE q.event_id = ? AND s.survey_type_id = 5 AND se.exhibitor_id=?", event_id, exhibitor_id])
  end

  def data
    responses.map {|r|
      row = [
        r[:survey_title],
        r[:heading],
        r[:subheading], # booth number
        r[:target_exhibitor],
        r[:first_name],
        r[:last_name],
        r[:company],
        r[:title],
        r[:city],
        r[:state],
        r[:country],
        r[:response_created].strftime('%D %r'),
        r[:response_updated].strftime('%D %r')
      ].concat(
        questions.map {|q|
          # this didn't work
          r.responses_for(q.survey_id, q.section_order, q.question_order).map {|r| 
            response = r[:response]
            if r[:question_type_id] == "4" && r[:response_answer_id].blank? && r[:response]
              ans_ids = r[:response].split(',')
              res = Answer.where(id: ans_ids).map(&:answer).join(', ')
              response = res
            elsif r[:question_type_id] == "1" && r[:original_response]
              res = Answer.where(id: r[:original_response]).first
              if res
                response = res.answer
              end
            end
            encode response}.join("\r\r")        
        }
      )
    }
  end

  def responses
    result = Response.find_by_sql([
      "SELECT s.title AS survey_title,
              s.id AS survey_id,
              ss.heading AS heading,
              ss.subheading AS subheading,
              at.first_name AS first_name,
              at.last_name AS last_name,
              at.company AS company,
              at.city AS city,
              at.state AS state,
              at.title AS title,
              at.country AS country,
              sr.created_at AS response_created,
              sr.updated_at AS response_updated,
              GROUP_CONCAT(
                  CONCAT( s.id, '^^', ss.order, '^^', q.order, '^^', q.question_type_id, '^^', IFNULL(r.answer_id, ''), '^^', IFNULL(r.response, ''), '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) SEPARATOR '||') AS survey_answers,
              s.survey_type_id
      FROM responses AS r
      LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id AND s.event_id = r.event_id
      LEFT JOIN questions        AS q  ON q.id                = r.question_id
      LEFT JOIN answers          AS a  ON a.id                = r.answer_id
      LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
      WHERE r.event_id=? AND survey_type_id=5 AND sr.exhibitor_id=?
      GROUP BY sr.id
      ORDER BY at.first_name, sr.created_at, ss.order, q.order, a.order", event_id, exhibitor_id ]).
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
            response_answer_id: parts[4],
            original_response: parts[5],
            response:         parts[6]
          }
        }

      def r.responses_for survey_id, section_order, question_order
        survey_answers.select {|r| r[:survey_id].to_i == survey_id && r[:section].to_i == section_order && r[:question].to_i == question_order}
      end
    }
    result
  end

end
