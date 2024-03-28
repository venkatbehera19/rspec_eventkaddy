## This controller is duplicated on the cms.eventkaddy site and used as the api for the cordova app there.

class SurveysApiController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:get_single_survey, :survey_results, :post_survey_response]
  # skip_before_action :verify_authenticity_token, only: [:get_single_survey, :survey_results, :post_survey_response]

  def get_single_survey
    if access_allowed?

      set_access_control_headers

      if params['api_proxy_key'] == API_PROXY_KEY
        result = ReturnSurveyObject.new(params['survey_id'], event_id:params['event_id'], account_code:params['attendee_account_code'],session_id:params['session_id']).call
      else
        result = {"error_messages" => ["Error: Incorrect proxy key."] }
      end
      render :json => result
    else
      head :forbidden
    end
  end

  def survey_results

  end

  def post_survey_response
    if access_allowed?

      set_access_control_headers
      survey_response = return_survey_response(params['event_id'], params['attendee_account_code'], params['survey_id'], params['session_id'])

      if params['api_proxy_key'] == API_PROXY_KEY
        result = UpdateSurveyResponse.new(survey_response, params['responses'], params['gps_location'], params['time_taken']).call
      else
        result = {"error_messages" => ["Error: Incorrect proxy key."]}
      end
      render :json => result
    else
      head :forbidden
    end
  end

  def options
    if access_allowed?
      set_access_control_headers; head :ok;
    else
      head :forbidden
    end
  end

  private

  def set_access_control_headers
    headers['Access-Control-Allow-Origin']  = '*' # request.env['HTTP_ORIGIN']
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age']       = '1000'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type'
    headers['Content-Type']                 = "text/javscript; charset=utf8"
  end

  def access_allowed?
    true
    #allowed_sites = [request.env['HTTP_ORIGIN']] #you might query the DB or something, this is just an example
    #return allowed_sites.include?(request.env['HTTP_ORIGIN'])
  end

  def return_survey_response(event_id, account_code, survey_id, session_id)
    session_id  = session_id.blank? ? nil : session_id
    attendee_id = Attendee.where(account_code:account_code, event_id:event_id).first.id
    SurveyResponse.where(event_id:event_id, session_id:session_id, survey_id:survey_id, attendee_id:attendee_id).first_or_create
  end
end
