class AttendeeBadgePrintsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action { set_ga_key('attendee_badge_print') }
  layout 'attendee_badge_print'

	def home
    @attendee_badge_print_settings = Setting.return_attendee_badge_settings(params[:event_id])
	end

	def home_exhibitor
		home
	end

	def home_speaker
		home
	end

	def search_attendee
		event_id = params["event_id"]
		searchText = params["searchText"]
		account_code = params["account_code"]
		attendee_badge_print_settings = Setting.return_attendee_badge_settings(event_id)
		error = ''
		attendeeType = params['attendeeType']
		if account_code.present?
			attendee = get_attendee attendeeType, 'account_code', account_code
		elsif attendee_badge_print_settings.search_attendee_by == 'account_code'
			attendee = get_attendee attendeeType, 'account_code', searchText
		elsif attendee_badge_print_settings.search_attendee_by == 'last_name'
			attendee = get_attendee attendeeType, 'last_name', searchText
		elsif attendee_badge_print_settings.search_attendee_by == 'first_name' 
			attendee = get_attendee attendeeType, 'first_name', searchText
		else
			error = 'No Attendee Found'
		end

		render json: {status: 'success', error: error, attendees: attendee, max_count: attendee_badge_print_settings.allowed_times_to_print_badge, use_pin: attendee_badge_print_settings.use_pin_for_security}
	end

	def print_badge
		event_id = params["event_id"]
		attendee_id = params["attendee_id"]
		@attendee_badge_print_settings = Setting.return_attendee_badge_settings(event_id)
		@attendee = Attendee.find_by(id: attendee_id, event_id: event_id)
		attendeeType = params['attendeeType']
		set_badge(attendeeType)
		printed_by = current_user || @attendee
		@attendee_badge_print = AttendeeBadgePrint.find_or_create_by(attendee_id: @attendee.id, badge_template_id: @badge.id, printed_by_id: printed_by.id, printed_by_type: printed_by.class.to_s)
		
		max_count = @attendee_badge_print_settings.allowed_times_to_print_badge == true ? 1 : @attendee_badge_print_settings.allowed_times_to_print_badge.to_i
		if @attendee_badge_print.count >= max_count
			render json: {error: "Max Limit Reached to print badge"}, status: 400
		else
			@attendee_badge_print.increment(:count, 1).save
			generate_zpl
		end
	end

	def print_badge_pin_based
		event_id = params["event_id"]
		attendee_pin = params['attendeePin']
		attendee_id = params['attendeeIdForPinBased']
		attendeeType = params['attendeeTypeForPinBased']
		@attendee_badge_print_settings = Setting.return_attendee_badge_settings(event_id)
		@attendee = Attendee.find_by(id: attendee_id, event_id: event_id, account_code: attendee_pin)
		set_badge(attendeeType)
		if @attendee && @badge
			generate_zpl
		elsif @badge.blank?
			render json: {status: 'error', message: 'Badge Not Found'}
		else
			render json: {status: 'incorrect_pin', message: 'Attendee Not Found'}
		end

	end

	def print_badge_over_ride
		event_id = params["event_id"]
		overRide = params['overRide']
		attendee_id = params['attendeeIdForPinBased']
		attendeeType = params['attendeeTypeForPinBased']
		@attendee_badge_print_settings = Setting.return_attendee_badge_settings(event_id)
		@attendee = Attendee.find_by(id: attendee_id)
		set_badge(attendeeType)
		if @attendee_badge_print_settings.overide_code == overRide && @badge && @attendee
			client = User.joins(:users_events, :roles).where(users_events: {event_id: 269}).find_by(roles: {name: 'Client'})
			printed_by = client || User.joins(:roles).where(roles: {name: 'SuperAdmin'}).first
			@attendee_badge_print = AttendeeBadgePrint.find_or_create_by(attendee_id: @attendee.id, badge_template_id: @badge.id, printed_by_id: printed_by.id, printed_by_type: printed_by.class.to_s)
			@attendee_badge_print.increment(:count, 1).save
			#here count is only for printed by User(Admin) not sumed with the printed by attendee by self
 			generate_zpl
		elsif @badge.blank?
			render json: {status: 'error', message: 'Badge Not Found'}
		else
			render json: {status: 'incorrect_pin', message: 'Incorrect Pin'}
		end
	end

	def generate_zpl
		@event_files = EventFile.where(name: @badge.json.keys.map!{|a| "badge_template_#{a}"})
		data = @attendee.as_json

		dataHash = @badge.json || {} 

 		badge_size_json = dataHash.select{|key, value| value['type'] == 'badge_size'}
 		
 		if badge_size_json.present?
 			badge_length = badge_size_json.values[0]['height'].to_i
			badge_width = badge_size_json.values[0]['width'].to_i
 		end

		zpl_string  = "^XA" 
		label = Zebra::Zpl::Label.new(
		  width:        badge_width || 400,
		  length:       badge_length || 300,
		  print_speed:  3
		)

		dataHash.each do |key, value|
			if value['textValue']
				to_be_printed = value["textValue"]
				to_be_printed = to_be_printed.gsub(/{{(.*?)}}/) do |match|
													data[$1]
												end

				if value["type"] == 'text'
					font_size     = "Zebra::Zpl::FontSize::SIZE_#{value["fontSize"]}".constantize 
					zpl  = Zebra::Zpl::Text.new(
					  data:       to_be_printed,
					  position:   [value["x"].to_f, value["y"].to_f],
					  font_size:  font_size
					)
				elsif value['type'] == 'qr'
					zpl = Zebra::Zpl::Qrcode.new(
					  data:             to_be_printed,
					  position:         [value["x"].to_f, value["y"].to_f],
					  scale_factor:     6,
					  correction_level: 'H'
					)
				elsif value['type'] == 'image'
					event_file = @event_files.find{|a| a.name == "badge_template_#{key}"}
					zpl = Zebra::Zpl::Image.new(
										path: event_file.return_authenticated_url['url'],
										position: [value["x"].to_f, value["y"].to_f],
										width: value["width"].to_f * 2,
										height: value["height"].to_f * 2,
										black_threshold: 0.3
									) if event_file
				end

				label << zpl
				zpl_string.concat(zpl.to_zpl)
			end
		end
		zpl_string.concat('^XZ')

		request_to_labelary zpl_string
		render json: {zpl_string: zpl_string, imgSrc: "/event_data/#{session[:event_id]}/badge_template_demo/demo.png", max_count: @attendee_badge_print_settings.allowed_times_to_print_badge, use_pin: @attendee_badge_print_settings.use_pin_for_security, count: @attendee_badge_print&.count, status: 'success'}
	end

	private

	def request_to_labelary zpl_string
		uri = URI 'http://api.labelary.com/v1/printers/8dpmm/labels/4x3/0/'
		http = Net::HTTP.new uri.host, uri.port
		request = Net::HTTP::Post.new uri.request_uri
		request.body = zpl_string
		response = http.request request
		target_path = Rails.root.join('public', 'event_data', session[:event_id].to_s, 'badge_template_demo', 'demo.png')

		case response
		when Net::HTTPSuccess then
		    File.open target_path, 'wb' do |f| 
		        f.write response.body
		    end
		else
		    puts "Error: #{response.body}"
		end
	end

	def get_attendee attendeeType, field, searchText
		event_id = params["event_id"]
		case attendeeType
		when 'exhibitor'
			attendee = Attendee.find_by_sql(["SELECT first_name, last_name, company, attendees.id, SUM(attendee_badge_prints.count) as count FROM attendees INNER JOIN booth_owners ON booth_owners.attendee_id = attendees.id LEFT OUTER JOIN attendee_badge_prints ON attendee_badge_prints.attendee_id=attendees.id WHERE event_id=? AND #{field}=? GROUP BY attendees.id", event_id, searchText])
		when 'speaker'
			#current using whole attendee to search, need to replaced by something associated with speakers
			attendee = Attendee.select('first_name, last_name, company, id').where(event_id: event_id).where("#{field} = ?", searchText)
		else
			attendee = Attendee.find_by_sql(["SELECT first_name, last_name, company, attendees.id, SUM(attendee_badge_prints.count) as count FROM attendees LEFT OUTER JOIN attendee_badge_prints ON attendee_badge_prints.attendee_id=attendees.id WHERE event_id=? AND #{field}=? GROUP BY attendees.id", event_id, searchText])
		end

		return attendee
	end

	def set_badge attendeeType
		case attendeeType
		when 'exhibitor'
			@badge = @attendee_badge_print_settings.badge_format_for_exhibitor.present? && BadgeTemplate.find_by(id: @attendee_badge_print_settings.badge_format_for_exhibitor)
		when 'speaker'
			@badge = @attendee_badge_print_settings.badge_format_for_speaker.present? && BadgeTemplate.find_by(id: @attendee_badge_print_settings.badge_format_for_speaker)
		else
			@badge = @attendee_badge_print_settings.badge_format_for_attendee.present? && BadgeTemplate.find_by(id: @attendee_badge_print_settings.badge_format_for_attendee)
		end
	end
end