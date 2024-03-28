class AttendeesAppBadgeTasksController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  # private

  # def attendees_app_badge_task_params
  #   params.require(:attendees_app_badge_task).permit(:event_id, :attendee_id, :app_badge_task_id, :app_badge_task_points_collected, :complete)
  # end

end