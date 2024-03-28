# AR environment needs to be loaded to use

module DatabaseAdjustment

  def self.remove_sessions_speaker_associations event_id
    session_ids = Session.where(event_id:event_id).pluck(:id)
    speaker_ids = Speaker.where(event_id:event_id).pluck(:id)
    SessionsSpeaker.where(session_id:session_ids).delete_all
    SessionsSpeaker.where(speaker_id:speaker_ids).delete_all
  end

end
