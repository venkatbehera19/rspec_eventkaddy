class Survey < ApplicationRecord

  extend SurveyFinders

  # special_location determines where in the app a survey should appear,
  # ie a global poll that must be linked on the attendee profile page

  has_many :survey_sessions, :dependent => :destroy
  has_many :sessions, :through => :survey_sessions
  has_many :survey_exhibitors, :dependent => :destroy
  has_many :survey_sections, :dependent => :destroy
  has_one  :survey_ce_certificate, :dependent => :destroy
  # has_many :questions, :dependent => :destroy
  has_many :questions
  has_many :survey_responses, :dependent => :destroy
  belongs_to :survey_type
  belongs_to :event

  def update_json
    result = HashifySurvey.new(id).call
    update! json: result['survey'].to_json if result['status']
  end

  def copy_to_event event_id
    r = MonkeySeeMonkeyDo.save_result_copy( MonkeySeeMonkeyDo.copy_model_to_event( schema(event_id) ) )
    r[:model].update_json
    r
  end

  def schema new_event_id
    ids = { event_id: new_event_id }
    {
      ids:     ids,
      model:   self,
      columns: :all,
      children: survey_sections.map {|ss|
        {
          model: ss,
          columns: :all,
          children: ss.questions.map {|q|
            {
              model: q,
              columns: :all,
              children: q.answers.map {|a| { model: a, columns: :all } }.
                concat( # hints are also a child of questions
                  q.hints.map {|h| { model: h, columns: :all } }
                ) # concat
            } # question children
          } # question map
        } # ss children
      } # ss map
    }
  end

  def update_ce_certificate_associations(params)
    ce_certificate_associations_to_delete = SurveyCeCertificate.where(survey_id:id).pluck(:ce_certificate_id)
    SurveyCeCertificate.where(ce_certificate_id:params[:ce_certificate_id], survey_id:id, event_id:event_id).first_or_create
    ce_certificate_associations_to_delete = ce_certificate_associations_to_delete - [params[:ce_certificate_id].to_i]
    SurveyCeCertificate.where(survey_id:id,ce_certificate_id:ce_certificate_associations_to_delete).delete_all
  end

  def update_exhibitor_associations(params)

    exhibitor_associations_to_delete = SurveyExhibitor.where(survey_id:id).pluck(:exhibitor_id)

    params[:exhibitor_ids].each do |e_id|
      SurveyExhibitor.where(exhibitor_id:e_id, survey_id:id, event_id:event_id).first_or_create
      exhibitor_associations_to_delete = exhibitor_associations_to_delete - [e_id.to_i]
    end

    SurveyExhibitor.where(survey_id:id,exhibitor_id:exhibitor_associations_to_delete).delete_all
  end

  def update_associations(params)

    session_associations_to_delete = SurveySession.where(survey_id:id).pluck(:session_id)

    params[:session_ids].each do |s_id|
      SurveySession.where(session_id:s_id, survey_id:id, event_id:event_id).first_or_create
      session_associations_to_delete = session_associations_to_delete - [s_id.to_i]
    end

    SurveySession.where(survey_id:id,session_id:session_associations_to_delete).delete_all
  end

  def self.bundle_session_survey_files(event_id)
    event           = Event.find event_id
    bundle_filename = "#{event.name}_session_survey_reports.zip"
    dir             = Rails.root.join('public','event_data', event_id.to_s,'session_survey_reports')

    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    FileUtils.cd(dir) do
	    FileUtils.rm bundle_filename, :force => true

      Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) { |zipfile|
        Dir.foreach(dir) do |item|
          next if item == '.' or item == '..'
          item_path = "#{dir}/#{item}"
          next if item_path.include? ".zip"
          zipfile.add("session_survey_reports/"+ item, item_path) if File.file?item_path
        end
      }
    	File.chmod(0644,bundle_filename)
	  end
  end

  def self.process_survey(params, event_id, attendee_id)
    account_code = Attendee.find(attendee_id).account_code
    if params['session_id']
      survey_response = SurveyResponse.where(event_id:event_id, attendee_id:attendee_id, attendee_account_code:account_code, survey_id:params['survey_id'],session_id:params['session_id']).first_or_create
    else
      survey_response = SurveyResponse.where(event_id:event_id, attendee_id:attendee_id, attendee_account_code:account_code, survey_id:params['survey_id']).first_or_create
    end
    params.each do |k, answer|
      if k.include? 'mc_question_'
        question_id = k.gsub('mc_question_', '')
        Response.where(event_id:event_id, survey_response_id:survey_response.id, question_id:question_id)
          .first_or_create
          .update!(answer_id:answer)
      elsif k.include? 'lf_question_'
        question_id = k.gsub('lf_question_', '')
        Response.where(event_id:event_id, survey_response_id:survey_response.id, question_id:question_id)
          .first_or_create
          .update!(response:answer)
      elsif k.include? 'r_question_'
        question_id = k.gsub('r_question_', '')
        Response.where(event_id:event_id, survey_response_id:survey_response.id, question_id:question_id)
          .first_or_create
          .update!(rating:answer)
      elsif k.include? 'ms_question_'
        question_id = k.gsub('ms_question_', '').split('/')[0]
        #multiple select questions can have multiple answers so using answer_id in query
        r = Response.where(event_id:event_id, survey_response_id:survey_response.id, question_id:question_id, answer_id:answer)
          .first_or_create
      end
    end
  end
end
