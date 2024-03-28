class AttendeeTextUpload < ApplicationRecord
  # attr_accessible :attendee_id, :attendee_text_upload_type_id, :event_id, :exhibitor_id, :session_id, :target_attendee_id, :text, :answer, :title, :session_code, :exhibitor_name, :target_attendee_name, :whitelist, :answered
  
  belongs_to :attendee

  def add_to_whitelist single_question_mode=false
    if single_question_mode
      self.class.where(session_id: session_id, whitelist: true).each do |t_u|
        t_u.update! whitelist: false
      end
    end
    update! whitelist: true
  end

  def revoke_from_whitelist
    update! whitelist: false
  end

  def self.reduce_to_one_whitelisted_question session_id
      where(
        session_id:                   session_id,
        attendee_text_upload_type_id: qa_type_id,
        whitelist:                    true).
        drop(1).
        each do |t_u|
          t_u.update! whitelist:false
        end
  end

  def self.qa_type_id
    AttendeeTextUploadType.where(name:"q&a").first.id
  end

  def self.qa_text_uploads_for_session session_id, question_ids=0
    # active record converts [] to null for the NOT IN (?) query,
    # which would return no results. So we change it to this impossible id
    # rails will also parse a blank array as nil if you send it in contentType
    # application/json, which will also return no result. So just change any blank
    # to 0
    question_ids = 0 if question_ids.blank?
    select('
      attendee_text_uploads.id,
      attendee_id,
      text,
      answer,
      attendee_text_upload_type_id,
      whitelist,
      answered,
      attendees.first_name AS first_name,
      attendees.last_name AS last_name')
    .joins('
      LEFT OUTER JOIN attendees ON attendee_text_uploads.attendee_id=attendees.id')
    .where('
      session_id=? AND
      attendee_text_upload_type_id=? AND
      attendee_text_uploads.id NOT IN (?)',
      session_id, qa_type_id, question_ids)
  end

  def self.whitelisted_qa_text_uploads_for_session session_id, question_ids=0
    # active record converts [] to null for the NOT IN (?) query,
    # which would return no results. So we change it to this impossible id
    # rails will also parse a blank array as nil if you send it in contentType
    # application/json, which will also return no result. So just change any blank
    # to 0
    question_ids = 0 if question_ids.blank?
    select('
      attendee_text_uploads.id,
      attendee_id,
      text,
      answer,
      attendee_text_upload_type_id,
      whitelist,
      answered,
      attendees.first_name AS first_name,
      attendees.last_name AS last_name')
    .joins('
      LEFT OUTER JOIN attendees ON attendee_text_uploads.attendee_id=attendees.id')
    .where('
      session_id=? AND
      whitelist = 1 AND
      attendee_text_upload_type_id=? AND
      attendee_text_uploads.id NOT IN (?)',
      session_id, qa_type_id, question_ids)
  end

end
