class AppMessageThreadsController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def index
    respond_to do |f|
      f.html
      f.json { render json: datatable_data }
    end
  end

  def show
    @app_message_thread = AppMessageThread
      .where(event_id: session[:event_id], id: params[:id])
      .first
  end

  # a kind of soft delete; hides the thread from attendees in the app
  def hide
    raise "Invalid Event ID" if session[:event_id] != @app_message_thread.event_id
    @app_message_thread.hide_for_all
    redirect_to "/app_message_threads/#{params[:id]}"
  end

  def unhide
    raise "Invalid Event ID" if session[:event_id] != @app_message_thread.event_id
    @app_message_thread.unhide_for_all
    redirect_to "/app_message_threads/#{params[:id]}"
  end

  private

  def datatable_data
    AppMessageThreadsDatatable.new( 
      params, session[:event_id], view_context
    ).datatable_data
  end

  # def app_message_thread_params
  #   params.require(:app_message_thread).permit(:event_id, :title, :active, :moderated, :moderator_attendee_id, :session_id)
  # end

end