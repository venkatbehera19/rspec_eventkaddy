class ConfirmationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'registration_portal'

  def create
    token     = params[:token]
    @user     = User.find_by_confirmation_token(token)
    @settings = Setting.return_cached_settings_for_registration_portal({ event_id:params[:event_id] })
    @event_id = params[:event_id]
    @verified = false
    if @user.blank? || @user.email != params[:user]
      @message = "Invalid verification link or the link has expired. Please regenerate verification email and try again."
    else
      if !!@user.confirmed_at
        @message                      = "Email address already verified."
        @verified                     = true
      else
        @user.confirm_user
        @message                      = "Email address verified successfully!"
        @settings                     = registration_portal_settings.json
        @event                        = Event.find params[:event_id]
        @verified                     = true
      end
    end
  end

  def resend
    @user      = User.find params[:id]
    @event     = Event.find params[:event_id]
    UserMailer.registration_confirmation(@event, @user).deliver_now
    redirect_to "/#{params[:event_id]}/registrations", :notice => "Confirmation Instructions has been sent to your email."
  end
end
