class FeedbacksController < ApplicationController
	load_and_authorize_resource

	#store the user's (anonymous) session rating and comment
  def create

  	rating = params["rating"]
  	comment = params["comment"]
  	session_id = params["session_id"]
  	event_id = params["event_id"]
  	@feedback = Feedback.new
		@feedback.rating = rating
		@feedback.comment = comment
		@feedback.session_id = session_id
		@feedback.event_id = event_id
		@feedback.save()

		@result = '{status:"success"}'
  	render :json => @result, :callback => params[:callback]
  end

  private

  # def feedback_params
  #   params.require(:feedback).permit(:event_id, :session_id, :speaker_id, :attendee_id, :rating, :comment)
  # end

end