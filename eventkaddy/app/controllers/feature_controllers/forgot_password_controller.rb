class ForgotPasswordController < ApplicationController

  def forgot_password_desktop
    @event = Event.find(64)
    render :layout => false
  end

  def retrieve_password
    # attendees = Attendee.where(event_id:params["event_id"],
    #                            email:params["email"])

    # password = attendees.first.password if attendees.length === 1

    # if password

    #   message = "Your Password is: #{password}"
    #   status  = "Success"
    #   hash    = [message:message,status:status,password:password]
    #   render :json => hash.to_json

    # elsif attendees.length > 1

    #   message = "We're sorry. There is more than one attendee with your email in our database for this event. Please contact your conference organizer for further assistance."
    #   status  = "Failure"
    #   hash    = [message:message,status:status]
    #   render :json => hash.to_json

    # else
    #   message = "We're sorry. We could not find an attendee with your email for this event. Please contact your conference organizer for further assistance."
    #   status  = "Failure"
    #   hash    = [message:message,status:status]
    #   render :json => hash.to_json

    # end
  end

  #API Endpoint for making reset password confirmation request
  def mobile_send_password_reset_confirmation
    puts "mobile_send_password_reset_confirmation"

    if access_allowed?

      set_access_control_headers
      headers['Content-Type'] = "text/javscript; charset=utf8"

      proxy_key = params['proxy_key']
      callback  = params['callback']
      user_name = params['user_name']
      event_id  = params['event_id']

      @result                   = {}
      @result["status"]         = 'false'
      @result["error_messages"] = []

      if (proxy_key === API_PROXY_KEY)

        @result["status"] = 'true'

        rows = Attendee.where(username:user_name,event_id:event_id)

        if rows[0]!=nil && rows.length===1 && !rows[0].email.blank?

          rows[0].generate_token
          rows[0].save

          AttendeeMailer.email_password_reset_confirmation(rows[0].email, rows[0].username, rows[0].token, Event.find(event_id)).deliver
        end

      else
        @result["error_messages"] << "Error: Incorrect proxy key."
      end
      render :json => @result.to_json, :callback => params['callback']
    else
      head :forbidden
    end
  end

  #API endpoint for reseting and emailing password
  def mobile_forgot_password

    user_name = params[:user_name]
    event_id  = params[:event_id]
    token     = params[:token]

    rows      = Attendee.where(username:user_name,event_id:event_id,token:token)

    if (rows[0]!=nil && rows.length===1 && !(rows[0].email.blank?)) then
      puts "cmsprod User Found: #{rows[0].username}"

      ## Not as secure as securerandom, but there's nothing to steal so it's okay.
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      rows[0].password = (0...6).map { o[rand(o.length)] }.join
      rows[0].save

      AttendeeMailer.email_password(rows[0].email, rows[0].password).deliver

      render :plain => "Password successfully reset! Please check your email for your new password."
    else
      render :plain => "Password could not be reset because the account was not found."
    end

  end

  def options
    puts "options method hit"
    if access_allowed?
      puts "access allowed hit"
      set_access_control_headers
      head :ok
    else
      puts "access forbiddon"
      head :forbidden
    end
  end

  private

  def get_client_attendees
    type_id = AttendeeType.where(name:"Client").first.id
    return Attendee.where(event_id:session[:event_id],attendee_type_id:type_id)
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin']  = '*' # request.env['HTTP_ORIGIN']
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age']       = '1000'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,x-requested-by,Content-Type'
  end

  def access_allowed?
    return true
    #allowed_sites = [request.env['HTTP_ORIGIN']] #you might query the DB or something, this is just an example
    #return allowed_sites.include?(request.env['HTTP_ORIGIN'])
  end

end