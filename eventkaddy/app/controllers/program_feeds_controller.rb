class ProgramFeedsController < ApplicationController
	layout :set_layout
	before_action :set_setting, except: [:favourite]
	before_action :authenticate_attendee

	def index
		@event = Event.find_by(id: params[:event_id])
		today_date_in_event_dates = (@event.event_start_at..@event.event_end_at).cover?(Date.today)
		event_default_date = today_date_in_event_dates ? Date.today : @event.event_start_at
		@sel_date = params[:date].present? ? params[:date] : event_default_date.to_s
		@sel_date = @event.event_start_at..@event.event_end_at if params[:date] == 'ALL'

		like_query = get_like_query_for('keyword', params[:keyword])
		tag_ids = get_tag_ids(params["tag_id"])

		if params[:date] == 'ALL'
			page = params[:sessionPage] || 1
			if params['sel'] == 'favourite' && @current_attendee
				@sessions = Session.joins(:attendees).where(attendees: {id: @current_attendee.id}, date: @sel_date).order('date, start_at')
			else
				@sessions = @event.sessions.where(date: @sel_date).order('date, start_at')
			end

			@sessions = @sessions.joins(:tags).where(tags: {id: tag_ids}) if tag_ids.present?
			session_search_by_query(params["search_query"]) 
			@sessions = @sessions.where(like_query) unless like_query.blank?
			@total_sessions  = @sessions.count 
			@total_pages = @total_sessions / 30.0
			@sessions = @sessions.offset((page.to_i - 1) * 30).limit(30)
		else
			if params['sel'] == 'favourite' && @current_attendee
				@sessions = Session.joins(:attendees).where(attendees: {id: @current_attendee.id}, date: @sel_date).order('start_at')
			else
				@sessions = @event.sessions.where(date: @sel_date).order('start_at')
			end

			@sessions = @sessions.joins(:tags).where(tags: {id: tag_ids}) if tag_ids.present?
			session_search_by_query(params["search_query"])
			@sessions = @sessions.where(like_query) unless like_query.blank?
		end
		
		@sessions = @sessions.includes(:speakers, :sponsors, :location_mapping)
		@sessions = @sessions.uniq.group_by(&:start_at)
		@sessions_attendees_ids = @current_attendee.sessions_attendees.map(&:session_id) if @current_attendee

		if request.xhr?
			render 'index.js.erb' and return
		else
			render :index and return
		end
	end

	def by_speakers
		sel_alphabet = params[:alphabet]
		search_query = params[:search_query]
		sel_alphabet = nil if sel_alphabet && sel_alphabet.downcase == 'all'
		page = params[:speakerPage] || 1
		tags = params[:tag_id]
		company_name = params[:companyName]
		like_query = get_like_query_for('company', company_name)

		@speakers = Speaker.includes({sessions_speakers: {session: :tags}}, :event_file_photo).where(sessions_speakers: {unpublished: false}).where(sessions: {event_id: params[:event_id], unpublished: false}).order('speakers.last_name')
		@companies = @speakers.pluck(:company).reject(&:blank?).uniq
		@speakers = @speakers.where('last_name like ?',"#{sel_alphabet}%") if sel_alphabet.present?
		@speakers = @speakers.where('concat(speakers.first_name, " ", speakers.last_name)like ?',"%#{search_query}%") if search_query.present?
		@speakers = @speakers.where(tags: {id: tags}) if tags.present?
		@speakers = @speakers.where(like_query) unless like_query.blank?
		get_keynote_speakers
		@total_pages = (@speakers.count - @keynote_speakers.count)/ 30.0
		@speakers = @speakers.offset((page.to_i - 1) * 30).limit(30).uniq
		@speakers = @speakers - @keynote_speakers
		@sessions_attendees_ids = @current_attendee.sessions_attendees.map(&:session_id) if @current_attendee

		if request.xhr?
			render 'by_speakers.js.erb' and return
		else
			render :by_speakers and return
		end
	end

	def speaker_sessions_details
		@speakers = Speaker.includes({sessions_speakers: {session: :tags}}, :event_file_photo).where(sessions_speakers: {unpublished: false}).where(sessions: {event_id: params[:event_id], unpublished: false}).order('speakers.last_name')
		@speaker = Speaker.find_by(id: params[:speaker_id])
		@sessions = []
		if @speaker
			@sessions = Session.joins(sessions_speakers: :speaker).where(speaker: {id: @speaker.id}).where(sessions_speakers: {unpublished: false}).where(event_id: params[:event_id], unpublished: false).order('date, start_at').group_by(&:start_at)
		end

		@sessions_attendees_ids = @current_attendee.sessions_attendees.map(&:session_id) if @current_attendee

		if request.xhr?
			render 'speaker_sessions_details.js.erb' and return
		end
	end

	def get_keynote_speakers
		@keynote_speakers = []
		if @settings.show_featured_speaker
			speaker_type_id = SpeakerType.find_by(speaker_type: "Keynote").id
			@keynote_speakers = @speakers.where(sessions_speakers: {speaker_type_id: speaker_type_id})
			page = params[:speakerKeynotePage] || 1
			@total_pages_keynote = @keynote_speakers.count / 3.0
			@keynote_speakers = @keynote_speakers.offset((page.to_i - 1) * 3).limit(3).uniq
		end
	end

	def by_keynote_speakers
		search_query = params[:search_query]
		tags = params[:tag_id]
		company_name = params[:companyName]
		like_query = get_like_query_for('company', company_name)

		@speakers = Speaker.includes({sessions_speakers: {session: :tags}}, :event_file_photo).where(sessions_speakers: {unpublished: false}).where(sessions: {event_id: params[:event_id], unpublished: false}).order('speakers.last_name')
		@speakers = @speakers.where('concat(speakers.first_name, " ", speakers.last_name)like ?',"%#{search_query}%") if search_query.present?
		@speakers = @speakers.where(tags: {id: tags}) if tags.present?
		@speakers = @speakers.where(like_query) unless like_query.blank?
		get_keynote_speakers
		if request.xhr?
			render 'by_keynote_speakers.js.erb' and return
		end
	end

	def by_exhibitors
		tag_ids = get_tag_ids(params["tag_id"])
		search_query = params[:search_query]
		sel_alphabet = params[:alphabet]
		sel_alphabet = nil if sel_alphabet && sel_alphabet.downcase == 'all'
		@exhibitor_attendees_ids = @current_attendee.exhibitor_attendees.map(&:exhibitor_id) if @current_attendee
		if params['sel'] == 'favourite' && @current_attendee
			@exhibitors = Exhibitor.includes(:tags, :location_mapping, [sponsor_level_type: :event_sponsor_level_types]).where(event_id: params[:event_id], id: @exhibitor_attendees_ids)
		else
			@exhibitors = Exhibitor.includes(:tags, :location_mapping, [sponsor_level_type: :event_sponsor_level_types]).where(event_id: params[:event_id])
		end
		@exhibitors = @exhibitors.where(tags: {id: tag_ids}) if tag_ids.present?
		@exhibitors = @exhibitors.where(sponsor_level_type: {id: params[:sponsor]}) if params[:sponsor].present?
		@exhibitors = @exhibitors.where('company_name like ?',"#{sel_alphabet}%") if sel_alphabet.present?
		@exhibitors = @exhibitors.where('company_name like ? or location_mappings.name like ?', "%#{search_query}%", "%#{search_query}%").references(:location_mappings)
		get_sponsored_exhibitor
		page = params[:exhibitorPage] || 1
		@total_pages = (@exhibitors.count - @sponsored_exhibitors.count)/ 30.0
		@exhibitors = @exhibitors.offset((page.to_i - 1) * 30).limit(30).uniq
		@exhibitors = @exhibitors - @sponsored_exhibitors
		if request.xhr?
			render 'by_exhibitors.js.erb' and return
		else
			render :by_exhibitors and return
		end
	end

	def exhibitor_sessions_details
		@exhibitors = Exhibitor.where(event_id: params[:event_id])
		@exhibitor = @exhibitors.find_by(id: params[:exhibitor_id])
		@sessions = @exhibitor.sessions.joins(:sessions_speakers).where(sessions_speakers: {unpublished: false}).where(unpublished: false).order('date, start_at').group_by(&:start_at)

		@sessions_attendees_ids = @current_attendee.sessions_attendees.map(&:session_id) if @current_attendee

		if request.xhr?
			render 'exhibitor_sessions_details.js.erb' and return
		end
	end

	def get_sponsored_exhibitor
		@sponsored_exhibitors = []
		if @settings.show_sponsored_exhibitor
			@sponsored_exhibitors = @exhibitors.where(is_sponsor: true).order('event_sponsor_level_types.rank').references(:event_sponsor_level_types)
			page = params[:exhibitorSponsorPage] || 1
			@total_pages_sponsor = @sponsored_exhibitors.count / 3.0
			@sponsored_exhibitors = @sponsored_exhibitors.offset((page.to_i - 1) * 3).limit(3).uniq
		end
	end

	def by_sponsor_exhibitors
		tag_ids = get_tag_ids(params["tag_id"])
		search_query = params[:search_query]
		@exhibitor_attendees_ids = @current_attendee.exhibitor_attendees.map(&:exhibitor_id) if @current_attendee
		if params['sel'] == 'favourite' && @current_attendee
			@exhibitors = Exhibitor.includes(:tags, :location_mapping, [sponsor_level_type: :event_sponsor_level_types]).where(event_id: params[:event_id], id: @exhibitor_attendees_ids)
		else
			@exhibitors = Exhibitor.includes(:tags, :location_mapping, [sponsor_level_type: :event_sponsor_level_types]).where(event_id: params[:event_id])
		end

		@exhibitors = @exhibitors.where(tags: {id: tag_ids}) if tag_ids.present?
		@exhibitors = @exhibitors.where(sponsor_level_type: {id: params[:sponsor]}) if params[:sponsor].present?
		@exhibitors = @exhibitors.where('company_name like ? or location_mappings.name like ?', "%#{search_query}%", "%#{search_query}%").references(:location_mappings)
		get_sponsored_exhibitor

		if request.xhr?
			render 'by_sponsor_exhibitors.js.erb' and return
		end
	end

	def get_like_query_for(query, parameter)
		like_query = ''

		return like_query if parameter.blank?
		parameter.each_with_index do |name, index|
			if index == 0  
				like_query.concat("#{query} like '%#{name}%'")
			else  
				like_query.concat(" or #{query} like '%#{name}%' ")
			end  
		end

		like_query
	end

	def get_tag_ids(parameter)
		tag_ids = []
		return tag_ids if parameter.blank?
		parameter.each do |id|
			tag = Tag.find(id)
			if tag.leaf
			  tag_ids << tag.id
			else  
			  tag_ids << tag.all_descendants.ids
			end  
		end 
		tag_ids.flatten!
		tag_ids
	end

	def session_search_by_query(parameter)
		return @sessions unless params.present?

		@sessions = @sessions.includes(:speakers).where('sessions.title like ? or sessions.session_code like ? or sessions.description like ? or sessions.keyword like ? or sessions.track_subtrack like ? or speakers.first_name like ?', "%#{parameter}%", "%#{parameter}%", "%#{parameter}%", "%#{parameter}%", "%#{parameter}%", "%#{parameter}%").references(:speakers)

		@sessions
	end

	def login_page
		redirect_to "/#{params[:event_id]}/program" if @current_attendee
		@event = Event.find_by(id: params[:event_id])
	end

	def login
		redirect_to "/#{params[:event_id]}/program" if @current_attendee

		attendee = Attendee.find_by(event_id: params["event_id"], email: params["attendee"]["email"], password: params["attendee"]["passw"])
		if attendee && params["attendee"]["email"].present?
			session[:program_feed_attendee] = attendee.id
			render json: {url: "/#{params[:event_id]}/program"}, status: '200'
		else
			render json: {message: 'Attendee not found'}, status: '401'
		end
	end

	def logout
		session.delete(:program_feed_attendee)
		redirect_to "/#{params[:event_id]}/program"
	end

	def favourite
		if @current_attendee
			if params[:type] == 'sessions'
				create_or_destroy_session_favourites
			elsif params[:type] == 'exhibitor'
				create_or_destroy_exhibitor_favourites
			elsif params[:type] == 'speaker'
				create_or_destroy_speaker_favourites
			end

			render json: {message: 'complete'}, status: '200'
		else
			render json: {message: 'Not Authorized'}, status: '401'
		end
	end

	def create_or_destroy_session_favourites
		session = Session.find_by(id: params[:record])
		session_attendee = SessionsAttendee.find_or_create_by(session: session, attendee: @current_attendee, session_code: session.session_code, flag: 'web')
		session_attendee.destroy if params[:isFavourite] == 'true'
	end

	def create_or_destroy_speaker_favourites
		sessions = Session.joins(sessions_speakers: :speaker).where(speaker: {id: params[:record]}).where(sessions_speakers: {unpublished: false}).where(event_id: params[:event_id], unpublished: false)

		session_attendees = SessionsAttendee.where(session: sessions.ids, attendee: @current_attendee)

		if params[:isFavourite] == 'true'
			session_attendees.destroy_all
		else
			not_favourite_session_ids = sessions.ids.map(&:to_s) - session_attendees.map(&:session_id)
			create_favourite_for_sessions = sessions.where(id: not_favourite_session_ids)
			create_favourite_for_sessions.each do |session|
				session_attendee = SessionsAttendee.find_or_create_by(session: session, attendee: @current_attendee, session_code: session.session_code, flag: 'web')
			end
		end
	end

	def create_or_destroy_exhibitor_favourites
		exhibitor = Exhibitor.find_by(id: params[:record])
		session_attendee = ExhibitorAttendee.find_or_create_by(exhibitor: exhibitor, attendee: @current_attendee, company_name: exhibitor.company_name, flag: 'web')
		session_attendee.destroy if params[:isFavourite] == 'true'
	end

	def my_favourite
		@event = Event.find_by(id: params[:event_id])
		today_date_in_event_dates = (@event.event_start_at..@event.event_end_at).cover?(Date.today)
		event_default_date = today_date_in_event_dates ? Date.today : @event.event_start_at
		@sel_date = params[:date].present? ? params[:date] : event_default_date.to_s
		@sel_date = @event.event_start_at..@event.event_end_at if params[:date] == 'ALL'
		@sessions = Session.joins(:attendees).where(attendees: {id: @current_attendee.id}).order('date, start_at')
		@sessions = @sessions.group_by(&:start_at)
		@sessions_attendees_ids = @current_attendee.sessions_attendees.map(&:session_id) if @current_attendee
	end

	def set_layout
		if action_name == 'login_page'
			"program_feed_login"
		else
			"program_feeds"
		end
	end

	def set_setting
		@settings = Setting.return_program_feed_booleans(params[:event_id])
	end

	def authenticate_attendee
		@current_attendee ||= Attendee.includes(:sessions_attendees, :exhibitor_attendees).find_by(id: session[:program_feed_attendee], event_id: params[:event_id])
	end

end
