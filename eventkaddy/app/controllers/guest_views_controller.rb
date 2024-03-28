# basically any pages we have that aren't part of a portal,
# ie that you shouldn't have to sign in to see
class GuestViewsController < ApplicationController
  layout 'blank'

  def daily_quote
    # get a random quote from a csv / database entry. Maybe a use a random
    # quote object that could be changed to use mysql if lots of events like
    # this in the future
    @quote = Rails.cache.fetch "daily-quote#{session[:event_id]}" do
      # headers false or first row turns into underscores (which would be for assigning hashes arrays, I guess)
      CSV.table( Rails.root.join( 'special_data/daily_quotes/208.csv' ), headers: false, :converters => [:all], :skip_blanks =>  true).to_a
    end.sample
  end

  def qa_feed
    @session                    = Session.find params[:session_id]
    @event                      = Event.find(@session.event_id)
    @enabled                    = guest_qa_enabled? @session.event_id
    @single_question_mode       = single_question_mode? @session.event_id
    @background_colour          = background_colour(@session.event_id)
    @title_background_colour    = title_background_colour(@session.event_id)
    @question_background_colour = question_background_colour(@session.event_id)
    @title_text_colour          = title_text_colour(@session.event_id)
    @question_text_colour       = question_text_colour(@session.event_id)
    @google_apis_font           = google_apis_font(@session.event_id)
    @banner                     = qa_page_banner_path(@session.event_id)
    @hide_session_title         = guest_qa_hide_session_title?(@session.event_id)
    @hide_attendee_name         = guest_qa_hide_attendee_name?(@session.event_id)
    @no_questions_header        = guest_qa_no_questions_header(@session.event_id)
    @no_questions_content       = guest_qa_no_questions_content(@session.event_id)
    render :text => "Session ID invalid." unless @session
  end

  def qa_ajax_data
    event_id = Session.find(params[:session_id]).event_id
    if whitelist_mode?(event_id) || single_question_mode?(event_id)
      render :json => {
        text_uploads: AttendeeTextUpload.whitelisted_qa_text_uploads_for_session(
                        params[:session_id],
                        params[:question_ids]
                      ),
        blacklist_ids: AttendeeTextUpload.where(
                         session_id: params[:session_id],
                         whitelist:  [false,nil]
                      ).pluck(:id)
      }
    else
      render :json => {
        text_uploads: AttendeeTextUpload.qa_text_uploads_for_session(
                        params[:session_id],
                        params[:question_ids]
                      ),
        blacklist_ids: []
      }
    end
  end

  private

  def cordova_bools event_id
    @cordova_bools ||= Setting.return_cordova_booleans( event_id )
  end

  def cordova_strings event_id
    @cordova_strings ||= Setting.return_cordova_strings( event_id )
  end

  def background_colour event_id
    "#" + (cordova_strings( event_id ).guest_qa_page_background_colour || 'FFF')
  end

  def title_background_colour event_id
    "#" + (cordova_strings( event_id ).guest_qa_page_title_background_colour || '8BA7B3')
  end

  def question_background_colour event_id
    "#" + (cordova_strings( event_id ).guest_qa_page_question_background_colour || '77DBEF')
  end

  def question_text_colour event_id
    "#" + (cordova_strings( event_id ).guest_qa_page_question_text_colour || '000')
  end

  def title_text_colour event_id
    "#" + (cordova_strings( event_id ).guest_qa_page_title_text_colour || 'FEFEFE')
  end

  def google_apis_font event_id
    font = cordova_strings( event_id ).guest_qa_page_google_apis_font
    font.blank? ? 'Roboto' : font
  end

  def guest_qa_no_questions_header event_id
    text = cordova_strings( event_id ).guest_qa_page_no_questions_header
    text.blank? ? '' : text
  end

  def guest_qa_no_questions_content event_id
    text = cordova_strings( event_id ).guest_qa_page_no_questions_content
    text.blank? ? '' : text
  end

  def qa_page_banner_path event_id
    cordova_strings( event_id ).guest_qa_page_banner_path
  end

  def whitelist_mode? event_id
    !!cordova_bools( event_id ).guest_qa_page_use_whitelist_enabled
  end

  def single_question_mode? event_id
    !!cordova_bools( event_id ).guest_qa_page_single_question_mode_enabled
  end

  def guest_qa_enabled? event_id
    !!cordova_bools( event_id ).guest_qa_page_webpage_enabled
  end

  def guest_qa_hide_session_title? event_id
    !!cordova_bools( event_id ).guest_qa_page_hide_session_title
  end

  def guest_qa_hide_attendee_name? event_id
    !!cordova_bools( event_id ).guest_qa_page_hide_attendee_name
  end

end
