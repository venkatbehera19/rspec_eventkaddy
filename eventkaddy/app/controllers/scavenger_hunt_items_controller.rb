class ScavengerHuntItemsController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  # replaced with scavenger hunt show page
#  def index
#    @scavenger_hunts      = ScavengerHunt.select('id, title').where(event_id:session[:event_id])
#    @scavenger_hunt_item  = ScavengerHuntItem.new
#    @scavenger_hunt_items = ScavengerHuntItem.where(event_id:session[:event_id]).order('scavenger_hunt_id')
#  end

  def create
    params[:scavenger_hunt_item][:event_id]          = session[:event_id]
    hunt_item_params = scavenger_hunt_item_params.to_h
    if scavenger_hunt_item_params[:scavenger_hunt_item_type_id].to_i != 1
      hunt_item_params.except!(:maximum_attempts)
    end
    # params[:scavenger_hunt_item][:scavenger_hunt_id] = params[:scavenger_hunt_id]
    item = ScavengerHuntItem.create!(hunt_item_params)
    item.update_image(params[:event_file]) if params[:event_file]
    redirect_to "/scavenger_hunts/#{item.scavenger_hunt_id}", notice: 'Successfully added scavenger hunt item.'
  end

  def update
    params[:scavenger_hunt_item][:event_id]          = session[:event_id]
    # params[:scavenger_hunt_item][:scavenger_hunt]
    # params[:scavenger_hunt_item][:scavenger_hunt_id] = params[:scavenger_hunt_id]
    item = ScavengerHuntItem.find(params[:id])
    item.update!(scavenger_hunt_item_params)
    item.update_image(params[:event_file]) if params[:event_file]
    redirect_to "/scavenger_hunts/#{item.scavenger_hunt_id}", notice: 'Successfully updated scavenger hunt item.'
  end

  def destroy
    item = ScavengerHuntItem.find(params[:id])
    item.destroy
    redirect_to "/scavenger_hunts/#{item.scavenger_hunt_id}"
  end

  private

  def scavenger_hunt_item_params
    params.require(:scavenger_hunt_item).permit(:answer, :scavenger_hunt_id, :description, :event_file_id, :event_id, :exhibitor_id, :name, :scavenger_hunt_item_type_id,:maximum_attempts)
  end

end