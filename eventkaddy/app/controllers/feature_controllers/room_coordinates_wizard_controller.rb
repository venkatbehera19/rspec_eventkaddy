class RoomCoordinatesWizardController < ApplicationController

  def update_coordinate
    JSON.parse(params[:Coordinate]).each do |c|

      @location_mapping   = LocationMapping.find(c["location_id"])
      @location_mapping.x = c["x"].to_i
      @location_mapping.y = c["y"].to_i
      @location_mapping.save()
    end
    render nothing: true
  end

  def ajax_room_data
    event_id          = session[:event_id]
    map_id            = params[:map_id]
    location_mappings = LocationMapping.where(event_id:event_id,map_id:map_id).order(:name)
    render :json => location_mappings
  end

  def ajax_array_of_all_location_mappings
    event_id          = session[:event_id]
    render :json => LocationMapping.where(event_id:event_id).pluck(:name)
  end

  def ajax_map_image_path
    event_id          = session[:event_id]
    map_id            = params[:map_id]
    event_map_path = EventMap.select('event_files.path AS path').joins('
      LEFT OUTER JOIN event_files ON event_files.id=event_maps.map_event_file_id
      ').where(event_id:event_id,id:map_id).first
    render :json => event_map_path
  end

  def ajax_remove_room_map_id
    location_mapping = LocationMapping.find(params[:location_mapping_id])
    if location_mapping.event_id===session[:event_id].to_i
      location_mapping.update!(map_id:nil,x:nil,y:nil)
    end

    render nothing: true
  end

  def create_room

    # def location_mapping_exists_and_isnt_already_in_map?
    #   @location_mapping!=nil && @location_mapping.map_id!=x["room_type_id"].to_i && @location_mapping.update!(map_id:x["map_id"])
    # end

    x = JSON.parse(params[:Room]).first

    location_mapping = LocationMapping.where(name:x["name"],event_id:session[:event_id],mapping_type:x["room_type_id"]).first_or_create

    respond_to do |format|
      if location_mapping.update!(map_id:x["map_id"])
        format.json  { render :json => location_mapping }
      # else
        # location_mappings.errors.add(:base,"Location has already been added to this map.") if location_mapping && location_mapping.map_id===x["map_id"].to_i
        # format.json { render :json => { :error => location_mapping.errors.full_messages }, :status => 422 }
      end
    end
  end

end