class AppBadgesController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def show
    @m = AppBadge.detailed_badge_info params[:id]
  end

  def new
    game_id = AppGame.where(event_id:session[:event_id]).first.id
    @m = {
      app_badge: AppBadge.new,
      app_game_id: game_id,
      app_badges: AppBadge.where(app_game_id:game_id).order(:position)
    }
  end

  def edit
    game_id = AppGame.where(event_id:session[:event_id]).first.id
    @m = {
      app_badge: AppBadge.find(params[:id]),
      app_game_id: game_id,
      app_badges: AppBadge.where(app_game_id:game_id).order(:position)
    }
  end

  def create
    app_badge          = AppBadge.new app_badge_params
    app_badge.event_id = session[:event_id]
    
    if app_badge.save validate: false
      app_badge.update_image params[:image_file] if params[:image_file]
      AppBadge.createAndUpdatePositions(params[:json], app_badge) unless params[:json].blank?
      redirect_to "/app_badges/#{app_badge.id}", notice: "Successfully created app badge"
    end
  end

  def update
    app_badge = AppBadge.find params[:id]
    AppBadge.updatePositions(params[:json]) unless params[:json].blank?
    if app_badge.update! app_badge_params
      app_badge.update_image params[:image_file] if params[:image_file]
      redirect_to "/app_badges/#{app_badge.id}", notice: "Successfully updated app badge"
    end
  end

  def destroy
    badge = AppBadge.find(params[:id])
    badge.updatePositionsAndDestroy(AppBadge.where(app_game_id:badge.app_game_id))
    redirect_to "/app_games/#{badge.app_game_id}", notice: "Successfully deleted app badge"
  end

  private

  def app_badge_params
    params.require(:app_badge).permit(:event_id, :app_game_id, :image_event_file_id, :alt_image_url, :name, :description, :details, :position, :min_badge_tasks_to_complete, :min_points_to_complete)
  end

end