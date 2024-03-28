class AppGamesController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def export_xlsx
    @event    = Event.find session[:event_id]
    @app_game = AppGame.where(event_id: session[:event_id], id: params[:id]).first
    render xlsx: "game_data", filename: "#{@event.name}_game_data.xlsx"
  end

  def leaderboard_for_projector
    @top_ten    = AttendeesAppBadge.top_ten_by_points params[:event_id]
    @event_name = Event.find(params[:event_id]).name
    @settings   = Setting.return_guest_view_settings( params[:event_id] )
    render layout: false
  end

  def leaderboard_for_projector_for_full_completion
    @top_ten     = AttendeesAppBadge.leaderboard_by_all_badges_completed_time params[:event_id], 10
    @event       = Event.find(params[:event_id])
    @event_name  = @event.name
    @event_start = @event.event_start_at
    @settings    = Setting.return_guest_view_settings( params[:event_id] )
    render layout: false
  end

  def index
    @m = {
      games: AppGame.where(event_id: session[:event_id]) 
    }
    if @m[:games].blank?
      redirect_to "/app_games/new" 
    else
      redirect_to "/app_games/#{@m[:games].first.id}"
    end
  end

  def show
    @m = AppGame.detailed_game_info params[:id]
  end

  def new
    @m = {app_game: AppGame.new}
  end

  def edit
    @m = {app_game: AppGame.find(params[:id])}
  end

  def create
    app_game          = AppGame.new app_game_params
    app_game.event_id = session[:event_id]
    redirect_to "/app_games/#{app_game.id}" if app_game.save
  end

  def update
    app_game = AppGame.find params[:id]
    redirect_to "/app_games/#{app_game.id}" if app_game.update!(app_game_params)
  end

  def destroy
    # not necessary for now. They can just set to inactive or delete it
  end

  private

  def app_game_params
    params.require(:app_game).permit(:event_id, :name, :description, :active)
  end

end