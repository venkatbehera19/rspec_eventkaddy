class HomeController < ApplicationController
  layout 'application_2013'

  #display orgs this user is associated with
  def index

		#check for fresh install
	 	@user= User.select('*')
	    if (@user.size == 0) then

	    	respond_to do |format|
	      		format.html { redirect_to('/users/new_install') }
	    	end

	    	return
	    end

	 	if (current_user!=nil) then
			if current_user.roles.length == 1

				if (current_user.role? :super_admin) then

					@events = Event.select('*')

					respond_to do |format|
						format.html { render :select_event, :layout => 'superadmin_2013'}
					end

				elsif (current_user.role? :client) then

					@events = Event.joins('
					LEFT OUTER JOIN users_events ON users_events.event_id=events.id').where("users_events.user_id = ?",current_user.id)

					respond_to do |format|
						format.html { render :select_event}
					end

				elsif (current_user.role? :track_owner) then
					if current_user.users_events.length == 1
						event_id = current_user.users_events.first.event_id
						role = current_user.roles.first.name
						link = "/events/change_event/#{event_id}/?role=#{role.downcase}"
						should_redirect = true
					else
						user = User.includes(:exhibitors, users_events: [:event]).where(users: { id: current_user.id } ).first
						@data = []
						user.users_events.each do |user_event|
							event = user_event.event
							exhibitor = user.exhibitors.find{ |k| k.event_id == event.id}
							@data << {
								event: {
									id: event.id,
									name: event.name,
									start_date: event.event_start_at,
									end_date: event.event_end_at,
									link: "/events/change_event/#{event.id}",
									roles: user_event.roles.pluck(:name)
								}
							}
						end
						should_redirect = false
					end
					respond_to do |format|
						if should_redirect
							format.html { redirect_to link }
						else
							format.html { render :select_role_event, :layout => 'trackownerportal_eventselect'}
						end
					end

				elsif (current_user.role? :speaker) then

					if current_user.users_events.length == 1
						event_id = current_user.users_events.first.event_id
						role = current_user.roles.first.name
						link = "/events/change_event/#{event_id}/?role=#{role.downcase}"
						should_redirect = true
					else
						user = User.includes(:exhibitors, users_events: [:event]).where(users: { id: current_user.id } ).first
						@data = []
						user.users_events.each do |user_event|
							event = user_event.event
							exhibitor = user.exhibitors.find{ |k| k.event_id == event.id}
							@data << {
								event: {
									id: event.id,
									name: event.name,
									start_date: event.event_start_at,
									end_date: event.event_end_at,
									link: "/events/change_event/#{event.id}",
									roles: user_event.roles.pluck(:name)
								},
								is_a_speaker: speaker.present?,
								speaker: {
									id: speaker&.id
								}
							}
						end
						should_redirect = false
					end

					respond_to do |format|
						if should_redirect
							format.html { redirect_to link }
						else
							format.html { render :select_role_event, :layout => 'speakerportal_eventselect_2013'}
						end
					end

				elsif (current_user.role? :exhibitor) then
					if current_user.users_events.length == 1
						event_id = current_user.users_events.first.event_id
						role = current_user.roles.first.name
						link = "/events/change_event/#{event_id}/?role=#{role.downcase}"
						should_redirect = true
					else
						user = User.includes(:speakers, users_events: [:event]).where(users: { id: current_user.id } ).first
						@data = []
						user.users_events.each do |user_event|
							event = user_event.event
							exhibitor = user.exhibitors.find{ |k| k.event_id == event.id}
							@data << {
								event: {
									id: event.id,
									name: event.name,
									start_date: event.event_start_at,
									end_date: event.event_end_at,
									link: "/events/change_event/#{event.id}",
									roles: user_event.roles.pluck(:name)
								},
								is_an_exhibitor: exhibitor.present?,
								exhibitor: {
									id: exhibitor&.id
								}
							}
						end
						should_redirect = false
					end

					respond_to do |format|
						if should_redirect
							format.html { redirect_to link }
						else
							format.html { render :select_role_event, :layout => 'exhibitorportal_eventselect'}
						end
					end

				elsif (current_user.role? :moderator) then
					if current_user.users_events.length == 1
						event_id = current_user.users_events.first.event_id
						role = current_user.roles.first.name
						link = "/events/change_event/#{event_id}/?role=#{role.downcase}"
						should_redirect = true
					else
						user = User.includes(:speakers, users_events: [:event]).where(users: { id: current_user.id } ).first
						@data = []
						user.users_events.each do |user_event|
							event = user_event.event
							exhibitor = user.exhibitors.find{ |k| k.event_id == event.id}
							@data << {
								event: {
									id: event.id,
									name: event.name,
									start_date: event.event_start_at,
									end_date: event.event_end_at,
									link: "/events/change_event/#{event.id}",
									roles: user_event.roles.pluck(:name)
								}
							}
						end
						should_redirect = false
					end
					respond_to do |format|
						if should_redirect
							format.html { redirect_to link }
						else
							format.html { render :select_role_event, :layout => 'exhibitorportal_eventselect'}
						end
					end
				elsif (current_user.role? :partner) then

					@events = Event.joins('
						LEFT OUTER JOIN users_events ON users_events.event_id=events.id').where("users_events.user_id = ?",current_user.id)

					respond_to do |format|
						format.html { render :select_event, :layout => 'moderatorportal_eventselect'}
					end

				elsif (current_user.role? :member) then

					@events = Event.includes(organization: :users).where(users: {id: current_user.id})
					@attendees = Attendee.where(event_id: @events.ids, email: current_user.email)

					respond_to do |format|
						format.html { render :select_event_for_members, :layout => 'member'}
					end

				elsif (current_user.role? :attendee) then
					if session[:event_id].blank?
						sign_out current_user
						respond_to do |format|
							flash[:alert] = "You are not authorized to login here!"
							format.html { redirect_to("/users/sign_in") } #special redirect for wvc 2014 speaker portal
						end
						return
					end
					user_attendee = get_user_attendee
					users_events  = UsersEvent.where(user_id: current_user.id, event_id: session[:event_id]).first
					if users_events.blank?
						UsersEvent.create(user_id: current_user.id, event_id: session[:event_id])
						flash[:notice] = "You have registered successfully!"
					end
					if !!current_user.confirmed_at
						respond_to do |format|
							# format.html { redirect_to "/#{session[:event_id]}/registrations/profile/#{user_attendee.slug}" }
							format.html { redirect_to "/attendee_portals/landing/#{user_attendee.slug}" }
						end
					else
						respond_to do |format|
							format.html { redirect_to "/#{session[:event_id]}/registrations/verify/#{user_attendee.slug}" }
						end
					end
				end

			else
				user = User.includes(:exhibitors, :speakers, users_events: [:event]).where(users: { id: current_user.id } ).first

				@data = []
				user.users_events.each do |user_event|
					event = user_event.event
					exhibitor = user.exhibitors.find{ |k| k.event_id == event.id}
					speaker = user.speakers.find{ |k| k.event_id == event.id}
					@data << {
						event: {
							id: event.id,
							name: event.name,
							start_date: event.event_start_at,
							end_date: event.event_end_at,
							link: "/events/change_event/#{event.id}",
							roles: user_event.roles.pluck(:name)
						},
						is_an_exhibitor: exhibitor.present?,
						is_a_speaker: speaker.present?,
						exhibitor: {
							id: exhibitor&.id
						},
						speaker: {
							id: speaker&.id
						}
					}
				end

				respond_to do |format|
					format.html { render :select_role_event, :layout => 'speakerportal_eventselect_2013'}
				end

			end

		else

			respond_to do |format|
				#format.html { render :index, :layout => 'splashpage_2013'	}
				format.html { redirect_to("/users/sign_in") } #special redirect for wvc 2014 speaker portal
				end

		end


  end #index

  #set which event data to edit
  #
  # Does this do anything? We're hitting the events/change_event endpoint
  def set_event

	 	@event = Event.find(params[:select_event_id])

		#store in session
		session[:event_id]   = @event.id
		session[:event_name] = @event.name

		#mark if the event has a speaker portal
		if ( eventHasPortal(@event.id)) then
			session[:event_has_portal]=true
		end

    raise current_user.role?(:track_owner).inspect

		if (current_user.role? :track_owner) then
			redirect_to "/trackowner_portals/landing"
		elsif (current_user.role? :speaker) then
			redirect_to "/speaker_portals/checklist"
 		elsif (current_user.role? :exhibitor) then
			redirect_to "/exhibitor_portals/landing"
 		elsif (current_user.role? :moderator) then
			redirect_to "/moderator_portals/landing"
		else
			redirect_to "/events/configure/#{params[:select_event_id]}"
 		end

  end #set_event

  def session_error

  end


  private

  # why do we need this at all? I should probably just make it always
  # session[:event_has_portal] true to avoid headaches
	def eventHasPortal(event_id)

		event = Event.find(event_id)
    event.domains.length > 0

	end

	def get_user_attendee
		attendee = Attendee.where(event_id: session[:event_id], user_id: current_user.id, email: current_user.email).first_or_create
	end

end
