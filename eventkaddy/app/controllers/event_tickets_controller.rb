class EventTicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_as_admin
  before_action :set_event
  before_action :set_ticket, only: [:edit, :update, :show, :destroy]
  layout :set_layout

  def index
    @tickets = EventTicket.where(event_id: session[:event_id])
  end

  def new
    @ticket = EventTicket.new
  end

  def create
    @ticket = EventTicket.new(event_ticket_param)
    if @ticket.save
      @ticket.upload_background_image(params[:background_image]) if params[:background_image].present?
      redirect_to "/event_tickets", notice: "Event Ticket Created Successfully"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @ticket.update(event_ticket_param)
      @ticket.upload_background_image(params[:background_image]) if params[:background_image].present?
      redirect_to "/event_tickets", notice: "Event Ticket Updated Successfully"
    else
      render :edit
    end
  end

  def show
  	
  end

  def destroy
  	@ticket.destroy if @ticket.present?
    redirect_to "/event_tickets", notice: "Event Ticket Destroyed"
  end


  private

  def event_ticket_param
  	params.require(:event_ticket).permit(:date, :start_time, :end_time, :event_id, :session_id, :description, :title, :location)
  end


  def verify_as_admin
    raise "Your not authorized for this action" unless current_user.role?("SuperAdmin")
  end

  def set_layout
    if current_user.role? :speaker
      'speakerportal_2013'
    elsif current_user.role? :exhibitor
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def set_ticket
  	@ticket = EventTicket.find_by(id: params[:id])
  end

  def set_event
  	@event = Event.find_by(id: session[:event_id])
  	redirect_to root_url if @event.blank?
  end
end
