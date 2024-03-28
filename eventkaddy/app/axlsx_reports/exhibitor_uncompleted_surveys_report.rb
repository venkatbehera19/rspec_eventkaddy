class ExhibitorUncompletedSurveysReport < AxlsxReport

  attr_reader :event_id, :exhibitor_id, :questions

  def initialize event_id, exhibitor_id, package, job=nil
    @exhibitor_id = exhibitor_id
    @event_id = event_id
    super package, job

    add_sheet "Uncompleted Surveys", [ heads ].concat( data )
  end

  def heads
    [
      "Survey Name","Exhibitor","First Name", "Last Name", "Company Name", "City", "State", "Country", "Created", "Updated" 
    ]
  end

  def data
    responses.map {|r|
      row = [
        r[:survey_title],
        r[:target_exhibitor],
        r[:first_name],
        r[:last_name],
        r[:company],
        r[:city],
        r[:state],
        r[:country],
        r[:response_created].strftime('%D %r'),
        r[:response_updated].strftime('%D %r')
      ]
    }
  end

  def responses
    result = SurveyResponse.find_by_sql([
      "SELECT s.title AS survey_title,
      e.company_name as target_exhibitor,
      s.id AS survey_id,
      at.first_name AS first_name,
      at.last_name AS last_name,
      at.company AS company,
      at.city AS city,
      at.state AS state,
      at.country AS country,
      sr.created_at AS response_created,
      sr.updated_at AS response_updated,
      s.survey_type_id
      FROM survey_responses AS sr
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
      LEFT JOIN exhibitors       AS e  ON e.id                = sr.exhibitor_id
      LEFT JOIN responses        AS r  on sr.id               = r.survey_response_id
      WHERE sr.event_id=? AND survey_type_id=5 AND sr.exhibitor_id=? AND r.survey_response_id IS NULL
      ORDER BY at.first_name, s.id, sr.created_at", event_id, exhibitor_id])
  end
end