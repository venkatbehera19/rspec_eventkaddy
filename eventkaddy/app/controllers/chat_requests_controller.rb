class ChatRequestsController < ApplicationController
	skip_before_action  :verify_authenticity_token #bypass CSRF token check


	def index
		render :json => "{}"
	end

	#return contact info for attendee
	def attendee_info
    	if access_allowed?
       		set_access_control_headers

       		account_code = params[:account_code]
       		event_id = params[:event_id]

       		result = {}
       		attendees = Attendee.where(event_id:event_id,account_code:account_code)
       		if (attendees.length == 1) then
				attendee = attendees.first
				result["valid_user"]=true
				result["first_name"]=attendee.first_name
				result["last_name"]=attendee.last_name
			else
				result["valid_user"]=false
			end

			render :json => result.to_json
		
		else
        	head :forbidden
		end
	end


	def options
		if access_allowed?
		  set_access_control_headers
		  head :ok
		else
		  head :forbidden
		end
	end

	private

	def set_access_control_headers 
		headers['Access-Control-Allow-Origin'] = '*' # request.env['HTTP_ORIGIN']
		headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
		headers['Access-Control-Max-Age'] = '1000'
		headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type'
	end

	def access_allowed?
		return true
		#allowed_sites = [request.env['HTTP_ORIGIN']] #you might query the DB or something, this is just an example
		#return allowed_sites.include?(request.env['HTTP_ORIGIN'])    
	end  
end
