class AttendeesAppBadgesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  # private

  # def attendees_app_badge_params
  #   params.require(:attendees_app_badge).permit(:event_id, :attendee_id, :app_badge_id, :app_badge_points_collected, :num_app_badge_tasks_completed, :complete, :prize_redeemed)
  # end

end