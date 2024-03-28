class GameResultsController < ApplicationController

  #RAILS4 TODO: before filter changes to before_action
  before_action :authorization_check
  layout false

  def game_results
    @event_id = params[:event_id]
    event_setting = EventSetting.where(event_id:params[:event_id]).first
    @banner_image = EventFile.where("id= ?",event_setting.portal_logo_event_file_id).first.path
    @attendees = GetAttendeeData.new(params[:event_id]).call
    @attendees = fill_in_email_data(@attendees, params[:event_id])
  end

  def download_game_results
    @attendees = GetAttendeeData.new(params[:event_id]).call
    @attendees = fill_in_email_data(@attendees, params[:event_id]).sort_by { |k| k["points"] }.reverse

    respond_to do |format|
      format.xlsx { render :action => :download_game_results, disposition: "attachment", filename: "game_results.xlsx" }
    end
  end

  private

  def fill_in_email_data(attendees, event_id)
    account_codes = []
    attendees.each { |a| account_codes << a['account_code'] }
    ar_attendees = Attendee.select('account_code, email')
                     .where('email IS NOT NULL')
                     .where(event_id:event_id, account_code:account_codes)
    attendees.each {|a|
      tmp = ar_attendees.select {|ar| tmp = ar.account_code == a['account_code']}
      a['email'] = tmp.length > 0 ? tmp[0].email : ''}
    attendees
  end

  def authorization_check
    authorize! :client, :all
  end

end
