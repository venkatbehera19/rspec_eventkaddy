class PartnerPortalsController < ApplicationController
  layout 'partnerportal'

  def landing
    @event = Event.find session[:event_id]
  end

end
