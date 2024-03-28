class RoomLayoutsController < ApplicationController
  layout :set_layout

  #layout 'subevent_2013'
  load_and_authorize_resource

  #GET
  #show session files
  def index

    @room_layouts = RoomLayout.where(event_id:session[:event_id])

    respond_to do |format|
      format.html # index.html.erb
    end

  end

  def new
    @room_layout = RoomLayout.new

    @location_mapping_type_id = LocationMappingType.where(type_name:'Room').first.id

    respond_to do |format|
      format.html # new.html.erb
    end

  end

  def create

    @room_layout = RoomLayout.new(room_layout_params)


    respond_to do |format|
      if @room_layout.save validate: false

        @room_layout.updateImage(params)
        @room_layout.updateDefault(params)

        format.html { redirect_to("/room_layouts", :notice => 'Room Layout successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end

  end

  def edit
    @room_layout = RoomLayout.find(params[:id])
    @location_mapping_type_id = LocationMappingType.where(type_name:'Room').first.id

  end

  def update
    @room_layout = RoomLayout.find(params[:id])

    respond_to do |format|
      if @room_layout.update!(room_layout_params)

          @room_layout.updateImage(params)
          @room_layout.updateDefault(params)

        format.html { redirect_to("/room_layouts", :notice => 'Room Layout successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end

  end

  def destroy
    @room_layout = RoomLayout.find(params[:id])
    @room_layout.delete

    respond_to do |format|
        format.html { redirect_to("/room_layouts", :notice => 'Room Layout successfully deleted.') }
    end
  end


  def session_links

    @session = Session.find(params[:session_id])

    @sessions_room_layouts = RoomLayout.select('room_layouts.*,sessions.id AS session_id').joins(
      'JOIN sessions_room_layouts ON room_layouts.id=sessions_room_layouts.room_layout_id
       JOIN sessions ON sessions_room_layouts.session_id=sessions.id'
       ).where('sessions.event_id=? AND sessions.id=?',session[:event_id],@session.id)

    @room_layouts = RoomLayout.where(event_id:session[:event_id],location_mapping_id:@session.location_mapping_id)

    @sessions_room_layout = SessionsRoomLayout.new

    respond_to do |format|
      format.html { render:'session_links' }
    end
  end

  def create_session_link

    @sessions_room_layout = SessionsRoomLayout.new(sessions_room_layout_params)

    respond_to do |format|
      if @sessions_room_layout.save
        format.html { redirect_to("/room_layouts/#{@sessions_room_layout.session_id}/session_links", :notice => 'Room Layout successfully created.') }
      else
        format.html { redirect_to("/room_layouts/#{@sessions_room_layout.session_id}/session_links", :notice => 'Room Layout could not be created.') }
      end
    end
  end

  def remove_session_link

    session_id=params[:session_id]
    room_layout_id=params[:room_layout_id]
    @sessions_room_layouts = SessionsRoomLayout.where(session_id:session_id,room_layout_id:room_layout_id)

    respond_to do |format|

      if ( @sessions_room_layouts.destroy_all )
        format.html { redirect_to("/room_layouts/#{session_id}/session_links", :notice => 'Room Layout successfully removed.') }
      else
        format.html { redirect_to("/room_layouts/#{session_id}/session_links", :notice => 'Room Layout could not be removed.') }
      end
    end

  end


  private

  def set_layout
    if current_user.role? :trackowner then
      session[:layout]
    elsif current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def room_layout_params
    params.require(:room_layout).permit(:event_id, :event_file_id, :room_layout_configuration_id, :title, :location_mapping_id, :default)
  end

  def sessions_room_layout_params
    params.require(:sessions_room_layout).permit(:event_id, :room_layout_id, :session_id)
  end

end