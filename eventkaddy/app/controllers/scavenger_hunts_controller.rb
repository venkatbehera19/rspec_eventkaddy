class ScavengerHuntsController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def index
    @m = {
      new_scavenger_hunt_url: "/scavenger_hunts/new",
      scavenger_hunts: ScavengerHunt.where(event_id: session[:event_id])
                        .map {|h|
                          {
                            title:        h.title,
                            description: h.description,
                            items_count: h.scavenger_hunt_items.count,
                            items_url:   "/scavenger_hunts/#{h.id}",
                            edit_url:    "/scavenger_hunts/#{h.id}/edit",
                            delete_url:  "/scavenger_hunts/#{h.id}"
                          }
                        }
    }
  end

  def show
    @m = ScavengerHunt.detailed_scavenger_hunt_info params[:id]
    @scavenger_hunt_item  = ScavengerHuntItem.new
  end

  def new
    @m = {scavenger_hunt: ScavengerHunt.new}
  end

  def edit
    @m = {scavenger_hunt: ScavengerHunt.find(params[:id])}
  end

  def create
    scavenger_hunt          = ScavengerHunt.new scavenger_hunt_params
    scavenger_hunt.event_id = session[:event_id]
    redirect_to "/scavenger_hunts/#{scavenger_hunt.id}" if scavenger_hunt.save
  end

  def update
    scavenger_hunt = ScavengerHunt.find params[:id]
    redirect_to "/scavenger_hunts/#{scavenger_hunt.id}" if scavenger_hunt.update!(scavenger_hunt_params)
  end

  # def destroy
  # end

  private

  def scavenger_hunt_params
    params.require(:scavenger_hunt).permit(:event_id, :title, :description, :begins, :ends,:maximum_attempts)
  end

end