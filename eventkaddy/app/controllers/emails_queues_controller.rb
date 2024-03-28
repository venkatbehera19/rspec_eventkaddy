class EmailsQueuesController < ApplicationController
  #RAILS4 TODO: before filter changes to before_action
  before_action :authorization_check, :model_for_id_and_event_id, :except => [:queue_exhibitor_staff_password_email]
  layout 'subevent_2013'

  def model
    EmailsQueue
  end

  # accessed from attendee show page probably
  def queue_email_password_for_model model
    model_name    = model.name.snakecase
    email_params  = {
      model:                    model,
      event_id:                 event_id,
      model_id:                 params["#{model_name}_id"],
      email_type:               'send_password',
      active_time:              nil,
      deliver_later:            0,
      template_id:              nil
    }
    result = EmailsQueue.method("queue_email").call email_params
    respond_to do |format|
      format.html { redirect_to "/#{model_name}s/#{params["#{model_name}_id"]}", :notice => result[:message] }
      format.json { render json: {stats: 'done'} }
    end
  end

  def queue_email_password_for_attendee
    queue_email_password_for_model Attendee
  end

  def queue_email_password_for_speaker
    queue_email_password_for_model Speaker
  end

  def queue_email_password_for_exhibitor
    queue_email_password_for_model Exhibitor
  end

  def queue_exhibitor_staff_password_email
    queue_email_password_for_model ExhibitorStaff
  end

  def queue_all_password_emails_for_model model
    model_name    = model.name.downcase
    result = EmailsQueue.method("queue_all_#{model_name}_password_emails").call event_id
    redirect_to "/emails_queues/show_all", :notice => result.inspect.gsub(',', '<br>').html_safe
  end

  def queue_all_attendee_password_emails
    queue_all_password_emails_for_model Attendee
  end

  def queue_all_speaker_password_emails
    queue_all_password_emails_for_model Speaker
  end

  def queue_all_exhibitor_password_emails
    queue_all_password_emails_for_model Exhibitor
  end

  def cancel_all
    respond_to do |f|
      if EmailsQueue.cancel_emails_for_event event_id
        f.html { redirect_to("/emails_queues/show_all", :notice => "Cancelled all pending emails for event.") }
      else
        f.html { redirect_to("/emails_queues/show_all", :notice => "Something went wrong.") }
      end
    end
  end

  def readd_to_queue
    if @email.readd_to_queue
      render json: {status: true, result:@email.inspect}
    else
      render json: {status: false, result:@email.inspect}
    end
  end

  # should this be used via ajax, rather than a redirect... that way you don't
  # lose your place in the table
  # ... yes
  def cancel
    render json: {status: true, result:@email.inspect}
  end

  def show_all
    @datatable = EmailsQueuesDatatable.new( params, event_id, view_context )
    respond_to do |f|
      f.html; f.json { render json:  @datatable.datatable_data }
    end
  end

  private

  def authorization_check
    #changed as clients can send these emails
    authorize! :client, :all
  end

  def model_for_id_and_event_id
    @email = for_event.where(id: params[:id]).first if params[:id]
  end

  def emails_queue_params
    params.require(:emails_queue).permit(:event_id, :email_type_id, :sent, :status, :email, :message, :attendee_id, :speaker_id, :exhibitor_id, :user_id, :trackowner_id)
  end

end