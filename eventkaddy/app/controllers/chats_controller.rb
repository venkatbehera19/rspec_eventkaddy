class ChatsController < ApplicationController
  layout :set_layout
  include ExhibitorPortalsHelper

  def index
    @event             = Event.find(session[:event_id])
    @exhibitor         = get_exhibitor
    @exhibitor && check_for_payment
    @exhibitor_id      = @exhibitor.id
    @exhibitor_details = @exhibitor.attributes.slice('id', 'company_name', 'contact_name', 'welcome_chat', 'enable_chat', 'unavailable_chat')
    @chats             = []
    @session_id        = false
  end

  def livestream
    @event           = Event.find(session[:event_id])
    @session         = Session.find params[:session_id]
    @session_title   = @session.title.gsub!(/[^0-9A-Za-z]/, '')
    @session_title   = @session.session_code + '_' + @session_title.underscore
    @session_id      = @session.id
    @exhibitor_id    = false
  end

  def update
    @exhibitor       = get_exhibitor
    @exhibitor.update!(exhibitor_params)
    redirect_to :action => 'index' and return
  end

  def enable
    @exhibitor       = get_exhibitor
    @exhibitor.update!(enable_chat: params[:enable_chat])
    redirect_to :action => 'index' and return
  end

  def enable_livestream
    @session  = Session.find params[:session_id]
    @session.update!(chat_enabled: params[:enable_chat])
    redirect_to :action => 'livestream'
  end

  def enable_moderator_notification_sound
    @session  = Session.find params[:session_id]
    @session.update!(enable_notification_sound: params[:session][:enable_notification_sound])
    redirect_to :action => 'livestream'
  end

  def download
    chatsdata = Nokogiri::HTML.parse(params["chatsData"])
    send_data(chatsdata, :filename => 'chats.html', disposition: "attachment") and return
  end

  private

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'moderatorportal'
    end
  end

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    else
      Exhibitor.find(params[:exhibitor_id])
    end
  end

  def exhibitor_params
    params.require(:exhibitor).permit(:contact_name, :welcome_chat, :unavailable_chat)
  end

end
