class CustomEmailsController < ApplicationController
  layout 'subevent_2013'

  def index
    email_type         = EmailType.find_by_name('send_generic_email')
    @custom_emails     = EmailsQueue.where(event_id: session[:event_id], email_type_id: email_type.id).order(:updated_at)
    @event             = Event.find session[:event_id]
  end

  def new
    @chosen_recipient  = User.find_by(id: params[:to].to_i) if params[:to]
    type_id            = EventFileType.find_by_name("email_template_image").id
    @event             = Event.find session[:event_id]
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:@event.id)
    @template_type     = TemplateType.find_by_name('generic_email_template')
    @template          = EmailTemplate.find_by(id: params[:template_id]) || EmailTemplate.new(
      template_type_id: @template_type.id,
      event_id:         @event.id
    )
    video_portal_booleans = Setting.return_video_portal_booleans(@event.id)
    @certificate       = video_portal_booleans.default_ce_id ? CeCertificate.find_by_id(video_portal_booleans.default_ce_id) : CeCertificate.where(event_id: session[:event_id]).last
    # Please note: link expiry has been set to 30 days of generation
    @Link_expiry_time  = Time.now.in_time_zone(@event.timezone) + 30.days
    # MessageVerifier is used here for encryption of query params
    @verifier = ActiveSupport::MessageVerifier.new(ENV['SALT'])
  end

  def create
    return if (params[:user_objects] == 'None' || params[:user_objects].blank?)
    user_objects = (params[:user_objects] == 'AttendeeWithSurveys' || params[:user_objects] == 'AttendeeWithoutSurveys' || params[:user_objects] == 'AttendeeAll') ? 'Attendee' : params[:user_objects]
    type            = TemplateType.find_by_name('generic_email_template')

    if !params[:active_time].blank?
      event         = Event.find session[:event_id]
      params[:active_time] = DateTime.strptime("#{params[:active_time]} #{event.utc_offset}","%m/%d/%Y %I:%M %p %:z")
    end

    template        = EmailTemplate.create template_params
    # model_name      = user_objects.snakecase
    params[:email][:recipients].each do |recipient_id|
      email_params  = {
        model:                    user_objects.constantize,
        event_id:                 session[:event_id],
        model_id:                 recipient_id,
        email_type:               'send_generic_email',
        active_time:              params[:active_time],
        deliver_later:            params[:deliver_later],
        attach_calendar_invite:   params[:attach_calendar_invite],
        template_id:              template.id
      }
      result = EmailsQueue.method("queue_email").call email_params

      if params[:user_objects] == 'Exhibitor' && params[:include_exhibitor_staffs]
        exhibitor        = Exhibitor.find recipient_id
        exhibitor_staffs = exhibitor.exhibitor_staffs
        exhibitor_staffs.each do |staff|
          email_params  = {
            model:                    ExhibitorStaff,
            event_id:                 session[:event_id],
            model_id:                 staff.id,
            email_type:               'send_generic_email',
            active_time:              params[:active_time],
            deliver_later:            params[:deliver_later],
            attach_calendar_invite:   params[:attach_calendar_invite],
            template_id:              template.id
          }
          EmailsQueue.method("queue_email").call email_params
        end
      end
    end

    redirect_to '/custom_emails', notice: "Email queued successfully."
  end

  def show
    @user_type   = params[:user_type]
    if @user_type.blank?
      redirect_to '/custom_emails', notice: "Something went wrong."
      return
    end
    @email_queue = EmailsQueue.find(params[:id])
    @template    = EmailTemplate.find @email_queue.template_id
  end

  def destroy
    @email_queue = EmailsQueue.find(params[:id])
    @email_queue.destroy

    respond_to do |format|
      format.html { redirect_to("/custom_emails") }
      format.xml  { head :ok }
    end
  end

  private
  def template_params
    params.require(:email_template).permit(:event_id, :template_type_id, :email_subject, :content)
  end

end
