class DownloadRequestsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  before_action :set_event

  def index
    event_id  = session[:event_id]
    @requests = DownloadRequest.where(event_id: event_id)
  end

  def request_file
    @request_files = DownloadRequest.where( user_id: current_user.id, event_id: @event.id )
  end

  def new

  end

  def create
    event_id     = params[:event_id]
    request_type = params[:request_type]
    user         = current_user
    event        = Event.find_by_id(event_id)

    # Check if there's an existing download request for the same file type and status is not 'success'
    existing_request = DownloadRequest.find_by( user_id: user.id, event_id: event.id, request_type: request_type, status: ['pending', 'processing']  )

    if existing_request

    else
      download_request = DownloadRequest.create(
        user: user,
        event: event,
        request_type: request_type,
        status: :pending
      )
      # Enqueue the download job using Sidekiq
      CreateZipFileWorker.perform_async(download_request.id)
    end

    redirect_to "/download_requests/request_file"
  end

  private

  def set_event
    event_id  = session[:event_id]
    @event = Event.find_by_id(event_id)
  end

end
