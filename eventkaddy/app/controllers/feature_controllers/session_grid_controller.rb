class SessionGridController < ApplicationController
  before_action :authorization_check

  def xls_grid
    @event_id = session[:event_id]
    render xlsx: "xls_grid", filename: "#{Event.find(session[:event_id]).name.downcase.gsub(/\s/,"_")}_session_grid.xlsx" 
  end

  def grid_view
    # params[:date] = Session.where(event_id:event_id).order('date').first.date unless params[:date]

    # SessionGridSetting.where(event_id:session[:event_id]).first_or_create

    @dates    = Session.where(event_id:session[:event_id]).where("date is not null").order("date").pluck(:date).uniq
    @date     = !params[:date].blank? ? Time.parse(params[:date]).strftime("%A, %B %d") : Time.parse(@dates.first.to_s).strftime("%A, %B %d")
    @c_date   = !params[:date].blank? ? Time.parse(params[:date]) : Time.parse(@dates.first.to_s)
    render :layout => false

  end

  def ajax_get_session_grid_settings
    settings =  SessionGridSetting.where(event_id:session[:event_id]).first_or_create.settings
    settings = '{"highlighted_tags":[]}' if settings.blank?
    render :json => settings
  end

  def ajax_push_session_grid_settings
    settings = JSON.parse(params[:new_settings])
    if SessionGridSetting.where(event_id:session[:event_id]).first.update!(settings:params[:new_settings])
      render :json => {success:true}
    end
  end

  def ajax_session_grid_autocomplete_data
    tag_type_id = TagType.where(name:'session').first.id
    auto_complete_data = Tag.where(event_id:session[:event_id],tag_type_id:tag_type_id).pluck(:name)
    auto_complete_data << Session.where(event_id:session[:event_id]).pluck(:title)
    render :json => auto_complete_data.flatten!.uniq
  end

  def ajax_session_grid_speakers_only_autocomplete_data
    auto_complete_data = []
    Speaker.where(event_id:session[:event_id]).each {|s| auto_complete_data << s.full_name}
    render :json => auto_complete_data.uniq
  end

  def ajax_session_grid_title_only_autocomplete_data
    render :json => Session.where(event_id:session[:event_id]).pluck(:title).uniq
  end

  # inefficient query?
  def ajax_session_grid_tags_only_autocomplete_data
    tag_type_id = TagType.where(name:'session').first.id
    render :json => Tag.where(event_id:session[:event_id],tag_type_id:tag_type_id).pluck(:name).uniq
  end

  def ajax_session_grid_sponsors_only_autocomplete_data
    sponsors = Exhibitor.where(event_id:session[:event_id]).pluck(:company_name)
    sponsors.each {|s| s.gsub!(/&#39;/, "'")}
    render :json => sponsors
  end

  # deprecated August 30 2019... just delete if nothing breaks in a month
  # def add_tags_to_ar_session(session)
  #   tags       = []
  #   tag_string = ''
  #   TagsSession.where(session_id:session["id"]).each do |session_tag|
  #     level       = session_tag.tag.level
  #     current_tag = session_tag.tag
  #     until level == -1
  #       tags        << current_tag.name
  #       current_tag = Tag.where(id:current_tag.parent_id).first
  #       level       = level - 1
  #     end
  #     tags.reverse.each_with_index {|t,i| if i===0 then tag_string=t else tag_string = "#{tag_string} | #{t}"; end }
  #   end
  #   session.merge!(:tags => tag_string)
  # end

  def ajax_session_data
    Rails.cache.fetch "session_grid_data-#{params[:event_id]}" do

      query = Session.
        select("sessions.id,
                date,
                session_code,
                sessions.title,
                DATE_FORMAT(start_at,\'%H:%i\') AS start_at,
                DATE_FORMAT(end_at,\'%H:%i\')   AS end_at,
                location_mappings.name AS location_name,
                exhibitors.company_name AS sponsors,
                GROUP_CONCAT( DISTINCT tags.bloodline SEPARATOR '&&' ) AS session_tag_bloodlines,
                CONCAT(IFNULL(speakers.honor_prefix,''),
                  IFNULL(speakers.first_name,''),
                  IFNULL(speakers.last_name,''),
                  IFNULL(speakers.honor_suffix,'')) AS speakers").
      where(event_id:params[:event_id]).
      joins("JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id").
      joins("LEFT JOIN sessions_sponsors ON sessions_sponsors.session_id=sessions.id").
      joins("LEFT JOIN exhibitors ON sessions_sponsors.sponsor_id=exhibitors.id").
      joins("LEFT JOIN sessions_speakers ON sessions_speakers.session_id=sessions.id").
      joins("LEFT JOIN speakers ON sessions_speakers.speaker_id=speakers.id").
      joins('LEFT OUTER JOIN tags_sessions ON sessions.id=tags_sessions.session_id').
      joins('LEFT OUTER JOIN tags ON tags_sessions.tag_id=tags.id AND tags.tag_type_id=1').
      where("location_mappings.name IS NOT NULL").
      where("location_mappings.name !=''").
      where("sessions.date IS NOT NULL").
      group('sessions.id').
      order("location_name, start_at")

      # for some reason this select all prevents the above query from doing
      # 1000 separate queries on its own. Probably I originally used it
      # specifically to override what rails was doing against my wishes... I
      # probably heard about this method on the ruby rogues podcast
      # It also does conveniently make it into an array of data that is easy to
      # work with, similar to as_json root:false
      ActiveRecord::Base.connection.select_all(query)
    end

    render :json => Rails.cache.read( "session_grid_data-#{params[:event_id]}")
  end

  def authorization_check
    authorize! :client, :all
  rescue # don't know how else to do this
    authorize! :trackowner, :all
  end

end
