class Poll < ApplicationRecord
  has_many :options, dependent: :destroy
  has_many :poll_sessions
  has_many :sessions, :through => :poll_sessions
  belongs_to :event
  attr_accessor :option_texts

  def update_associations(session_ids,options)
    session_associations_to_delete = PollSession.where(poll_id:id).pluck(:session_id)
    session_ids.each do |s_id|
      PollSession.where(session_id:s_id, poll_id:id, event_id:event_id, title: title, response_limit: response_limit, options_select_limit: options_select_limit, allow_answer_change: allow_answer_change, timeout_time: timeout_time).first_or_create do |poll_session|
        options.each do |option| 
          SessionPollOption.create(poll_session: poll_session, option_text: option.text)
        end  
      end  
      # session_associations_to_delete = session_associations_to_delete - [s_id.to_i]
    end
    # PollSession.where(poll_id:id,session_id:session_associations_to_delete).delete_all
  end
  
end
