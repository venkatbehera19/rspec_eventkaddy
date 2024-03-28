class GenerateLeadSurveyReport

  attr_reader :attendee_id, :event_id, :filename

  def initialize attendee_id, event_id, filename
    @attendee_id = attendee_id
    @event_id    = event_id
    @filename    = filename
  end

  def responses_by_survey
    Response.find_by_sql([
      "SELECT s.title,
              s.id AS survey_id,
              ss.heading,
              ss.subheading,
              ta.id AS target_attendee_id,
              at.account_code,
              at.first_name,
              at.last_name,
              ta.first_name AS lead_first_name,
              ta.last_name AS lead_last_name,
              ta.company AS lead_company,
              ta.email AS lead_email,
              ta.business_phone AS lead_business_phone,
              ta.mobile_phone AS lead_mobile_phone,
       GROUP_CONCAT(
           CONCAT( ss.order, '.', q.order, '. ', q.question) ORDER BY ss.order, q.order SEPARATOR '||'
       ) AS survey_questions,
       GROUP_CONCAT(
           CONCAT( ss.order, '^^', q.order, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) ORDER BY ss.order, q.order SEPARATOR '||'
       ) AS survey_answers,
       s.survey_type_id
      FROM responses AS r
      LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
      LEFT JOIN questions        AS q  ON q.id                = r.question_id
      LEFT JOIN answers          AS a  ON a.id                = r.answer_id
      LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
      LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id
      WHERE at.id=? AND survey_type_id=6
      GROUP BY sr.id
      ORDER BY s.id, at.account_code, ta.id, ss.order, q.order, a.order", attendee_id]
    )
  end

  def responses_by_response
    # Although it works in mysql, find_by_sql needs me to make these awkward renaming of some columns like question, rating, and answer
    # not sure if every IFNULL evaluates; if so, IF THEN ELSEIF might be faster
    Response.find_by_sql([
      "SELECT s.title,
              ss.heading,
              ss.subheading,
              se.id AS session_id,
              ta.id AS target_attendee_id,
              at.account_code,
              at.first_name,
              at.last_name,
              ta.company AS lead_company,
              ta.email AS lead_email,
              ta.business_phone AS lead_business_phone,
              ta.mobile_phone AS lead_mobile_phone,
              ta.first_name AS lead_first_name,
              ta.last_name AS lead_last_name,
              q.order,
              q.question AS survey_question,
              IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) AS response_answer,
              a.correct,
              s.survey_type_id
      FROM responses AS r
      LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
      LEFT JOIN questions        AS q  ON q.id                = r.question_id
      LEFT JOIN answers          AS a  ON a.id                = r.answer_id
      LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
      LEFT JOIN sessions         AS se ON se.id               = sr.session_id
      LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id
      WHERE at.id=? AND survey_type_id=6
      ORDER BY s.title, at.account_code, se.id, ta.id, ss.order, q.order, a.order", attendee_id]
    )
  end

  def responses_by_survey_with_attendee_scan
    AttendeeScan.find_by_sql([
    "SELECT ats.id,
            ats.initiating_attendee_id,
            ta.id AS target_attendee_id,
            at.account_code,
            at.first_name,
            at.last_name,
            ta.first_name AS lead_first_name,
            ta.last_name AS lead_last_name,
            ta.company AS lead_company,
            ta.email AS lead_email,
            ta.business_phone AS lead_business_phone,
            ta.mobile_phone AS lead_mobile_phone
    FROM attendee_scans AS ats
    LEFT JOIN events AS e ON e.id = ats.event_id
    LEFT JOIN attendees AS at ON at.id = ats.initiating_attendee_id
    LEFT JOIN attendees AS ta ON ta.id = ats.target_attendee_id
    where at.id=? AND attendee_scan_type_id = 6
    GROUP BY ats.id
    ORDER BY at.account_code, ta.id", attendee_id])
  end

  def check_survey_response_for_scan
    results = responses_by_survey_with_attendee_scan
    new_arr = []
    results.each do |r| 
      sr = SurveyResponse.where(attendee_id: r.initiating_attendee_id, target_attendee_id: r.target_attendee_id)
      if sr.length > 0
        name = sr.first.survey.title
        new_arr << [name, r.lead_first_name, r.lead_last_name, r.lead_company, r.lead_email, r.lead_mobile_phone, r.lead_business_phone]
      else
        new_arr << ["", r.lead_first_name, r.lead_last_name, r.lead_company, r.lead_email, r.lead_mobile_phone, r.lead_business_phone]
      end
    end
    new_arr
  end

  def headers
    ["Survey Name", "First Name", "Last Name", "Company Name", "Email", "Mobile Phone", "Business Phone", "Question", "Answer"]
  end

  def call
    # data = [headers].concat(
    #   responses_by_response.map {|r|
    #     # add a space before response to left align number answers
    #     [r.title, r.lead_first_name, r.lead_last_name, "#{r.order}. #{ r.survey_question }", " #{r.response_answer}"]
    #   }
    # )

    last_survey_id = nil
    last_survey_id_for_attendee_scan = nil

    data = []

    # have to use each instead of map here, due to special case of adding two rows
    responses_by_survey.each do |r|
      # headers and current row for new survey
      # This won't actually style them correctly as is... I have to give up
      # SimpleXLSXTable or update it if I want that
      unless r.survey_id == last_survey_id
        last_survey_id = r.survey_id
        data << ["Survey Name", "First Name", "Last Name", "Company Name", "Email", "Mobile Phone", "Business Phone"].concat(
          # group_by then map to avoid duplicate questions
          r.survey_questions.split('||').group_by {|a| a[0..4] }.values.map {|a| a[0] }
        )
      end
      data << [r.title, r.lead_first_name, r.lead_last_name, r.lead_company, r.lead_email, r.lead_mobile_phone, r.lead_business_phone].
        concat(
          r.survey_answers.
            split('||').
            group_by {|a| a[0..4] }.
            values.
            map {|a|
              # remove the section and question order values
              a.map{|x| x.split('^^').last}.join(', ')
            }
        )
    end

    attendee_scan_data = []
    attendee_scan_data << ["Survey Name", "First Name", "Last Name", "Company Name", "Email", "Mobile Phone", "Business Phone"]

    check_survey_response_for_scan.each do |r|
      attendee_scan_data << r
    end


    path    = Rails.root.join('public', 'event_data', event_id.to_s, 'generated_lead_surveys', filename)
    dirname = File.dirname( path )
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    p = Axlsx::Package.new
    p.use_shared_strings = true
    wb = p.workbook

    SimpleXlsxTable.add_sheet wb, "Lead Surveys", data, [20, 20, 20].concat( data[0].map{|x| 40 } ) unless data.empty?

    SimpleXlsxTable.add_sheet wb, "Attendee Scan", attendee_scan_data, [20, 20, 20].concat( attendee_scan_data[0].map{|x| 40 } ) unless attendee_scan_data.empty?

    p.serialize( path )
    path
  end

end

# Attendee.where(last_name:'Ault', event_id: 193).first.id # 285365
# GenerateLeadSurveyReport.new(285365, 193, 'test.xlsx').call.to_s.split('public') # ["/Users/edwardgallant/working_copies/lodestar/eventkaddy/", "/event_data/193/generated_lead_surveys/test.xlsx"]