class IattendScansByAttendeeReport < AxlsxReport

  attr_reader :event_id, :questions

  def initialize event_id, package, job=nil
    super package, job
    @event_id = event_id
    add_sheet "Kiosk", [ kiosk_heads ].concat( kiosk_data )
    add_sheet "Sessions", [ iattend_heads ].concat( iattend_data )
  end

  def session_data
    @session_data ||= Session.select('title, session_code').where(event_id:event_id).as_json(root:false)
  end

  def session_info_for_session_codes session_codes
    return '' unless session_codes && session_codes.length > 0
    session_codes = session_codes.split(',')
    session_data.
      select {|s| session_codes.include? s["session_code"] }.
      map {|s| "#{s["session_code"]} - #{s["title"]}" }.
      join("\r\r") # must use "" not '', or the \r gets interpretted literally
      # join("\x0D\x0A")
  end

  def iattend_heads
    [ "Last Name", "First Name", "Company", "Title", "Email", "Address", "City", "State", "Zip", "Country", "Business Phone", "Mobile Phone", "Account Code",
      "Campaign Name", # this is the event name
      "Sessions" ]
  end

  # our existing query pulls all data by the booth owner. This time we have to pull by the lead the survey was about.
  def kiosk_heads
    [
      "Booth Name", "Rep Name", # name of the exhibitor attendee who filled out the survey
      "Last Name", "First Name", # this is the name of the attendee who was scanned... the lead. so all the surveys they did are in one cell
      "Company", "Title", "Email", "Address", "City", "State", "Zip", # custom_filter_1 for the event in question
      "Country", "Business Phone", "Mobile Phone", "Account Code" ].
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

  def kiosk_data
    Response.lead_survey_results_grouped(event_id).map {|r|
      row = [
        r[:company_names],
        r[:rep_names],
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
        r[:lead_account_code]
      ].concat(
        questions.map {|q|
          r.responses_for(q.survey_id, q.section_order, q.question_order).
            map {|r|
            begin
              SimpleXlsxTable.encode "#{r[:company_name]}\r#{r[:response]}"
            rescue => e
              raise "Error while concatenating. '#{r[:company_name]}' and '#{r[:response]}'.\r #{e.message}"
              # raise "Error while adding row to sheet. #{row.inspect}"
            end
          }.join("\r\r")
        }
      )
    }
  end

  def iattend_data
    event_name = Event.find( event_id ).name
    Attendee.where(event_id: event_id).map { |a|
      [
        a[:last_name],
        a[:first_name],
        a[:company],
        a[:title],
        a[:email],
        a[:address],
        a[:city],
        a[:state],
        a[:custom_filter_1], # zip
        a[:country],
        a[:business_phone],
        a[:mobile_phone],
        a[:account_code],
        event_name, # campaign
        session_info_for_session_codes( a[:iattend_sessions] )
      ]
    }
  end
end
