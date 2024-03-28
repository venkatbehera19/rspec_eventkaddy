class Response < ApplicationRecord
  belongs_to :event
  belongs_to :survey_response
  belongs_to :answer, :optional => true
  belongs_to :question
  belongs_to :verifier,foreign_key: :verifier_id, class_name: :User, optional: true

  enum image_status: {
    rejected: 0,
    verified: 1,
    pending: 2
  }
  class ConcatenationError < StandardError; end

  def self.lead_survey_results_grouped event_id
    find_by_sql([
      "SELECT s.title,
              s.id AS survey_id,
              ss.heading,
              ss.subheading,
              ta.id AS target_attendee_id,
              ta.iattend_sessions,
              at.account_code,
              GROUP_CONCAT( DISTINCT CONCAT(at.first_name, ' ', at.last_name)  SEPARATOR ', ')  AS rep_names,
              GROUP_CONCAT( DISTINCT e.company_name SEPARATOR ', ') AS company_names,
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
              # GROUP_CONCAT(
              #     DISTINCT CONCAT( s.id, '^^', s.title, '^^', ss.order, '^^', q.order, '^^', q.question) ORDER BY s.id, ss.order, q.order SEPARATOR '||'
              # ) AS survey_questions,
              GROUP_CONCAT(
                  CONCAT( e.company_name, '^^', s.id, '^^', ss.order, '^^', q.order, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) SEPARATOR '||'
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
      WHERE r.event_id=? AND survey_type_id=6
      GROUP BY sr.id
      ORDER BY ta.id, s.id, at.account_code, ss.order, q.order, a.order", event_id
    ]).
    group_by {|r| r.target_attendee_id }. # cannot do this in query because a group_concat would exceed sql character limit
    map {|k, v|
      v.reduce {|x, y|
        begin
          x.survey_answers = x.survey_answers + '||' + y.survey_answers
        rescue
          raise ConcatenationError.new("An error occured while concatenating '#{x.survey_answers}' and '#{y.survey_answers}'")
        end
        begin
          x.company_names = x.company_names + ', ' + y.company_names
        rescue
          raise ConcatenationError.new("An error occured while concatenating '#{x.company_names}' and '#{y.company_names}'")
        end
        begin
          x.rep_names = x.rep_names + ', ' + y.rep_names
        rescue
          raise ConcatenationError.new("An error occured while concatenating '#{x.rep_names}' and '#{y.rep_names}'")
        end
        # x.survey_questions = x.survey_questions + '||' + y.survey_questions
        x
      }
    }.each {|r|
      r.survey_answers = (r.survey_answers || '').
        split('||').
        # group_by {|a| "#{ a.split('^^')[1] }#{ a.split('^^')[2] }#{ a.split('^^')[3] }"  }. # we no longer need the array of arrays if we use responses for
        # map {|k, v| # maybe we want to keep keys for convenience of looking up the question
        map {|r|
          parts = r.split('^^')
          {
            company_name: parts[0],
            survey_id:    parts[1],
            section:      parts[2],
            question:     parts[3],
            response:     parts[4]
          }
        }
        # }
      def r.responses_for survey_id, section_order, question_order
        survey_answers.select {|r| r[:survey_id].to_i == survey_id && r[:section].to_i == section_order && r[:question].to_i == question_order }
      end

      # r.survey_questions = r.
      #   survey_questions.
      #   split('||').uniq
      #   group_by {|a| a.split('^^')[0..2].join('^^') }.
      #   map {|k, v|
      #     v.map {|r|
      #       parts = r.split('||')
      #       "Company Name: #{parts[0]}\rSection: #{parts[1]}\rQuestion: #{parts[2]}\rResponse: #{parts[3]}"
      #     }.join("\r\r")
      #   }
    }
  end

  # def lead_survey_results event_id
  #   find_by_sql(["SELECT s.title,
  #           s.id AS survey_id,
  #           ss.heading,
  #           ss.subheading,
  #           ta.id AS target_attendee_id,
  #           at.account_code,
  #           at.first_name,
  #           at.last_name,
  #           e.company_name AS company_name,
  #           ta.first_name AS lead_first_name,
  #           ta.last_name AS lead_last_name,
  #           ta.company AS lead_company,
  #           ta.email AS lead_email,
  #           ta.business_phone AS lead_business_phone,
  #           ta.mobile_phone AS lead_mobile_phone,
  #           ta.title AS lead_title,
  #           ta.address AS lead_address,
  #           ta.city AS lead_city,
  #           ta.state AS lead_state,
  #           ta.country AS lead_country,
  #           ta.account_code AS lead_account_code,
  #           ta.custom_filter_1 AS lead_custom_filter_1,
  #    GROUP_CONCAT(
  #        CONCAT( ss.order, '.', q.order, '. ', q.question) ORDER BY ss.order, q.order SEPARATOR '||'
  #    ) AS survey_questions,
  #    GROUP_CONCAT(
  #        CONCAT( ss.order, '^^', q.order, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) ORDER BY ss.order, q.order SEPARATOR '||'
  #    ) AS survey_answers,
  #    s.survey_type_id
  #   FROM responses AS r
  #   LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
  #   LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
  #   LEFT JOIN questions        AS q  ON q.id                = r.question_id
  #   LEFT JOIN answers          AS a  ON a.id                = r.answer_id
  #   LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
  #   LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id # this is the exhibitor making the survey
  #   LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id # this is the person the survey is about
  #   LEFT JOIN booth_owners     AS bo ON at.id               = bo.attendee_id
  #   LEFT JOIN exhibitors       AS e  ON e.id                = bo.exhibitor_id
  #   WHERE r.event_id=? AND survey_type_id=6
  #   GROUP BY sr.id
  #   ORDER BY s.id, at.account_code, ta.id, ss.order, q.order, a.order", event_id])
  # end

  # this query hits the character limit once enough surveys have been filled
  # out about a lead attendee... ie that group concat for the survey_answers is too large.
  #
  # So the only way to do this is going to be to do that query separately, annoyingly enough. Or not group by ta.id
  # def self.lead_survey_results_grouped event_id
  #   find_by_sql(["
  #   SELECT s.title,
  #           s.id AS survey_id,
  #           ss.heading,
  #           ss.subheading,
  #           ta.id AS target_attendee_id,
  #           at.account_code,
  #           GROUP_CONCAT( DISTINCT CONCAT(at.first_name, ' ', at.last_name)  SEPARATOR ', ')  AS rep_name,
  #           GROUP_CONCAT( DISTINCT e.company_name SEPARATOR ', ') AS company_names,
  #           ta.first_name AS lead_first_name,
  #           ta.iattend_sessions AS lead_iattend_sessions,
  #           ta.last_name AS lead_last_name,
  #           ta.company AS lead_company,
  #           ta.email AS lead_email,
  #           ta.business_phone AS lead_business_phone,
  #           ta.mobile_phone AS lead_mobile_phone,
  #           ta.title AS lead_title,
  #           ta.city AS lead_city,
  #           ta.state AS lead_state,
  #           ta.country AS lead_country,
  #           ta.account_code AS lead_account_code,
  #           ta.custom_filter_1 AS lead_custom_filter_1,
  #           GROUP_CONCAT(
  #               DISTINCT CONCAT( ss.order, '.', q.order, '. ', q.question) ORDER BY ss.order, q.order SEPARATOR '||'
  #           ) AS survey_questions,
  #           GROUP_CONCAT(
  #               CONCAT( e.company_name, '^^', ss.order, '^^', q.order, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) SEPARATOR '||'
  #           ) AS survey_answers,
  #           s.survey_type_id
  #   FROM responses AS r
  #   LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
  #   LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
  #   LEFT JOIN questions        AS q  ON q.id                = r.question_id
  #   LEFT JOIN answers          AS a  ON a.id                = r.answer_id
  #   LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
  #   LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
  #   LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id
  #   LEFT JOIN booth_owners     AS bo ON at.id               = bo.attendee_id
  #   LEFT JOIN exhibitors       AS e  ON e.id                = bo.exhibitor_id
  #   WHERE r.event_id=? AND survey_type_id=6
  #   GROUP BY ta.id
  #   ORDER BY s.id, at.account_code, ta.id, ss.order, q.order, a.order", event_id])
  # end
end
