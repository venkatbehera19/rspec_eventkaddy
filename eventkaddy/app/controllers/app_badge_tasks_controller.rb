class AppBadgeTasksController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def show
    @m = AppBadgeTask.detailed_badge_task_info params[:id]
  end

  def new
    @m = {
      app_badge_task:  AppBadgeTask.new,
      app_badge_id:    params[:app_badge_id],
      possible_types:  AppBadgeTaskType.all,
      hunt_items:      ScavengerHuntItem.where(event_id: session[:event_id]),
      surveys:         Survey.where(event_id: session[:event_id]),
      app_badge_tasks: AppBadgeTask.where(app_badge_id:params[:app_badge_id]).order(:position)
    }
  end

  def edit
    app_badge_task = AppBadgeTask.find params[:id]
    badge_type     = app_badge_task.app_badge_task_type
    @m = {
      app_badge_task: app_badge_task,
      app_badge_id:   app_badge_task.app_badge_id,
      type:           badge_type,
      possible_types: AppBadgeTaskType.all,
      hunt_items:     ScavengerHuntItem.where(event_id: session[:event_id]),
      surveys:         Survey.where(event_id: session[:event_id]),
      app_badge_tasks: AppBadgeTask.where(app_badge_id:app_badge_task.app_badge_id).order(:position)
    }
  end

  def create
    scavenger_hunt_task_type_id = AppBadgeTaskType.where(name:"Scavenger Hunt Item Badge Task").first.id
    params[:app_badge_task][:scavenger_hunt_item_id] = params[:app_badge_task][:app_badge_task_type_id] == scavenger_hunt_task_type_id.to_s ? params[:app_badge_task][:scavenger_hunt_item_id] : nil

    def is_survey_task_id? id
      survey_task_type_ids = AppBadgeTaskType.where(
        name: [
          "Session Survey Badge Task",
          "CE Session Survey Badge Task",
          "Single Session Survey Badge Task",
          "Survey Participation Badge Task",
          "Quiz Badge Task"
        ]
      ).pluck(:id)
      survey_task_type_ids.include? id.to_i
    end

    params[:app_badge_task][:survey_id] =
      if is_survey_task_id? params[:app_badge_task][:app_badge_task_type_id]
        params[:app_badge_task][:survey_id]
      else
        nil
      end

    app_badge_task          = AppBadgeTask.new app_badge_task_params
    app_badge_task.event_id = session[:event_id]
    if app_badge_task.save!
      AppBadgeTask.createAndUpdatePositions(params[:json], app_badge_task) unless params[:json].blank?
      app_badge_task.update_image params[:image_file] if params[:image_file]
      redirect_to "/app_badge_tasks/#{app_badge_task.id}", notice: "Successfully created app badge task"
    end
  end

  def update
    scavenger_hunt_task_type_id = AppBadgeTaskType.where(name:"Scavenger Hunt Item Badge Task").first.id
    params[:app_badge_task][:scavenger_hunt_item_id] = params[:app_badge_task][:app_badge_task_type_id] == scavenger_hunt_task_type_id.to_s ? params[:app_badge_task][:scavenger_hunt_item_id] : nil

    def is_survey_task_id? id
      survey_task_type_ids = AppBadgeTaskType.where(
        name: [
          "Session Survey Badge Task",
          "CE Session Survey Badge Task",
          "Single Session Survey Badge Task",
          "Survey Participation Badge Task",
          "Quiz Badge Task"
        ]
      ).pluck(:id)
      survey_task_type_ids.include? id.to_i
    end

    params[:app_badge_task][:survey_id] =
      if is_survey_task_id? params[:app_badge_task][:app_badge_task_type_id]
        params[:app_badge_task][:survey_id]
      else
        nil
      end

    app_badge_task = AppBadgeTask.find params[:id]
    AppBadgeTask.updatePositions(params[:json]) unless params[:json].blank?
    if app_badge_task.update! app_badge_task_params
      app_badge_task.update_image params[:image_file] if params[:image_file]
      redirect_to "/app_badge_tasks/#{app_badge_task.id}", notice: "Successfully updated app badge task"
    end
  end

  def destroy
    badge_task = AppBadgeTask.find(params[:id])
    badge_task.updatePositionsAndDestroy(AppBadgeTask.where(app_badge_id: badge_task.app_badge_id))
    redirect_to "/app_badges/#{badge_task.app_badge_id}", notice: "Successfully deleted app badge task"
  end

  private

  def app_badge_task_params
    params.require(:app_badge_task).permit(:event_id, :app_badge_id, :image_event_file_id, :alt_image_url, :name, :description, :details, :position, :app_badge_task_type_id, :scavenger_hunt_id, :scavenger_hunt_item_id, :survey_id, :points_per_action, :points_to_complete, :max_points_allotable, :max_points_per_action)
  end

  # def app_badge_params
  #   params.require(:app_badge).permit(:event_id, :app_game_id, :image_event_file_id, :alt_image_url, :name, :description, :details, :position, :min_badge_tasks_to_complete, :min_points_to_complete)
  # end

end
