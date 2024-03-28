class EmailsQueue < ApplicationRecord
  # attr_accessible :attendee_id, :email, :email_type_id, :event_id, :exhibitor_id, :message, :sent, :speaker_id, :trackowner_id, :user_id, :status
  belongs_to :email_type
  belongs_to :event
  [ :attendee, :exhibitor, :speaker, :trackowner, :user ].each {|table|
    belongs_to table, :optional => true
  }

  def readd_to_queue
    update! sent: false, status: 'pending'
  end

  # unused
  def self.queue_email_sign_up_tokens_for_event event_id, model
    model.where(event_id: event_id).each do |m|
      next if m.email.blank?
      where(
        event_id:      event_id,
        email:         m.email,
        status:        'reviewing', # an intermediary review stage before user will set status to pending
        email_type_id: 2,
        message:       sign_up_token_message,
        "#{ model.name.downcase }_id".to_sym => m.id # mixing hash syntax is apparently ok
      ).first_or_create
    end
  end

  def self.queue_email_sign_up_tokens_for_event! event_id, model

  end

  # may eventually be used
  def self.cancel_emails_for_event event_id
    where(event_id: event_id, status:'pending').update_all status: 'cancelled'
  end

  def self.cancel_all_emails
    where(status:'pending').update_all status: 'cancelled'
  end

  def self.queue_email email_params
    email_type_id = EmailType.where(name: email_params[:email_type]).first.id
    model         = email_params[:model]
    m             = model.where(event_id: email_params[:event_id], id: email_params[:model_id]).first
    model_name    = model.name.snakecase
    return {status: false, message: "#{model_name.titleize} does not exist."} unless m
    unless m.email.blank?
      if email_params[:template_id]
        email = where(event_id: email_params[:event_id], email_type_id: email_type_id, template_id:email_params[:template_id],  email: m.email, "#{model_name}_id".to_sym => m.id).first
      else
        email = where(event_id: email_params[:event_id], email_type_id: email_type_id, email: m.email, "#{model_name}_id".to_sym => m.id).first
      end
      if !email
        create!(
          event_id:      email_params[:event_id],
          email_type_id: email_type_id,
          email:         m.email,
          sent:          0,
          status:        'pending',
          active_time:   email_params[:active_time],
          deliver_later: email_params[:deliver_later],
          attach_calendar_invite: email_params[:attach_calendar_invite],
          template_id:   email_params[:template_id],
          "#{model_name}_id".to_sym => m.id
        )
        {status: true, message: "Added #{model_name} send password email to emails queue."}
      elsif email.status != 'pending'
        email.readd_to_queue
        {status: true, message: "Added #{model_name} send password email to emails queue. Was previously queued."}
      else
        {status: false, message: "#{model_name.titleize} already in queue."}
      end
    else
      {status: false, message: "#{model_name.titleize} could not be added to queue. Missing email address."}
    end
  end

  # def self.queue_attendee_password_email event_id, attendee_id, email_type, active_time=nil, deliver_later=0
  #   queue_password_email_for_model Attendee, event_id, attendee_id, email_type, active_time, deliver_later
  # end

  # def self.queue_speaker_password_email event_id, speaker_id, email_type, active_time=nil, deliver_later=0
  #   queue_password_email_for_model Speaker, event_id, speaker_id, email_type, active_time, deliver_later
  # end

  # def self.queue_exhibitor_password_email event_id, exhibitor_id, email_type, active_time=nil, deliver_later=0
  #   queue_password_email_for_model Exhibitor, event_id, exhibitor_id, email_type, active_time, deliver_later
  # end

  # def self.queue_exhibitor_staff_password_email event_id, exhibitor_staff_id, email_type, active_time=nil, deliver_later=0
  #   queue_password_email_for_model ExhibitorStaff, event_id, exhibitor_staff_id, email_type, active_time, deliver_later
  # end

  # def self.queue_password_email_for_model(model, event_id, model_id, email_type, active_time, deliver_later)
  #   email_type_id = EmailType.where(name:email_type).first.id
  #   m             = model.where(event_id: event_id, id: model_id).first
  #   model_name    = model.name.snakecase
  #   return {status: false, message: "#{model_name.titleize} does not exist."} unless m
  #   unless m.email.blank?
  #     email = where(event_id: event_id, email_type_id: email_type_id, email: m.email, "#{model_name}_id".to_sym => m.id).first
  #     if !email
  #       create(
  #         event_id:      event_id,
  #         email_type_id: email_type_id,
  #         email:         m.email,
  #         sent:          0,
  #         status:        'pending',
  #         active_time:    active_time,
  #         deliver_later:  deliver_later,
  #         "#{model_name}_id".to_sym => m.id
  #       )
  #       {status: true, message: "Added #{model_name} send password email to emails queue."}
  #     elsif email.status != 'pending'
  #       email.readd_to_queue
  #       {status: true, message: "Added #{model_name} send password email to emails queue. Was previously queued."}
  #     else
  #       {status: false, message: "#{model_name.titleize} already in queue."}
  #     end
  #   else
  #     {status: false, message: "#{model_name.titleize} could not be added to queue. Missing email address."}
  #   end
  # end

  def self.queue_all_attendee_password_emails event_id
    queue_all_password_emails_for_model Attendee, event_id
  end

  def self.queue_all_exhibitor_password_emails event_id
    queue_all_password_emails_for_model Exhibitor, event_id
  end

  def self.queue_all_speaker_password_emails event_id
    queue_all_password_emails_for_model Speaker, event_id
  end

  # lifted from custom_adjustment_script
  def self.queue_all_password_emails_for_model model, event_id
    email_type_id                      = EmailType.where(name:'send_password').first.id
    emails_added                       = 0
    models_without_emails              = 0
    models_already_have_email_in_queue = 0

    model_name = model.name.downcase

    model.where(event_id:event_id).each do |m|
      unless m.email.blank?
        unless where(event_id: event_id, email_type_id: email_type_id, email: m.email, "#{model_name}_id".to_sym => m.id).first
          create(
            event_id:      event_id,
            email_type_id: email_type_id,
            email:         m.email,
            sent:          0,
            status:        'pending',
            "#{model_name}_id".to_sym => m.id
          )
          emails_added += 1
        else
          models_already_have_email_in_queue += 1
        end
      else
        models_without_emails += 1
      end
    end

    {
      emails_added: emails_added,
      "#{model_name}s_without_emails".to_sym              => models_without_emails,
      "#{model_name}s_already_have_email_in_queue".to_sym => models_already_have_email_in_queue
    }
  end

  private

  # unused: using mailer instead
  # We won't actually have the specific date until review messages are set to
  # pending.  Or the password reset link for that matter. But they can be added
  # at that stage, or perhaps just before the mailer ships the email out.
  # Frankly the text here could just as well go in the mailer, I'm just
  # following my original design where I had envisioned being able to write the
  # email. Maybe it makes more sense to leave the message null, and when a
  # message is null, to rely on its type to select the view template
  def self.sign_up_token_message
    <<-EOM
    Please follow this link by ---DATE--- to set the password for your new account:

    ---SET PASSWORD LINK---

    If you remember your password and don't wish to change it, you can follow this link to disable the above set password link:

    ---DISABLE SET PASSWORD LINK---

    If you do not know your password, and you missed the above cut off date, you can still use the forgot password link to receive a new link to reset your password.

    ---GENERIC FORGOT PASSWORD LINK---

    EOM
  end

end
