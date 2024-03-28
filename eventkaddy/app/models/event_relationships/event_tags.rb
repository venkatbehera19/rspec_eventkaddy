require "#{Rails.root}/ek_scripts/utility-functions.rb"

module EventTags

  def remove_session_tags(tag_type_id)

    Tag.where(event_id:id,tag_type_id:tag_type_id).each do |tag|
      tag.destroy unless tag.sessions.length === 0
    end
  end

  def remove_exhibitor_tags(tag_type_id)

    Tag.where(event_id:id,tag_type_id:tag_type_id).each do |tag|
      tag.destroy unless tag.exhibitors.length === 0
    end
  end

  def is_a_date?(string)
    ## yyyy-mm-dd
    date_exp = /^\d\d\d\d[- \/.](0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])$/
    result   = date_exp =~ string
    !result.nil? ? true : false
  end

  def get_local_start_time(start_at)
    Time.at(start_at).change(:offset => utc_offset).strftime('%T')
  end

  def remove_date_tags(tag_set, top_level_tag)
    tag_set.each {|a| tag_set = tag_set - [a] if is_a_date? a[0] }
    tag_set.each {|a| tag_set = tag_set - [a] if a[0] === top_level_tag } if top_level_tag
    tag_set
  end

  def add_date_tags(session, tag_set, top_level_tag)
    date     = session.date
    start_at = get_local_start_time(session.start_at)
    tag_set  = remove_date_tags(tag_set, top_level_tag)
    if top_level_tag
      tag_set << [top_level_tag, date, start_at]
    else
      tag_set << [date, start_at]
    end
  end

  def remove_location_tags(tag_set, top_level_tag, event_maps)
    tag_set.each {|a| tag_set = tag_set - [a] if event_maps.include? a[0] }
    tag_set.each {|a| tag_set = tag_set - [a] if a[0] === top_level_tag } if top_level_tag
    tag_set
  end

  def add_session_location_tags(session, tag_set, top_level_tag, event_maps)
    event_map = session.event_map.name
    room      = session.location_mapping.name
    tag_set   = remove_location_tags(tag_set, top_level_tag, event_maps)
    if top_level_tag
      tag_set << [top_level_tag, event_map, room]
    else
      tag_set << [event_map, room]
    end
  end

  def add_tags_for_sessions_template(template, complete_tags_array, top_level_tag)

    complete_tags_array.each do |h|

      sessions = Session.where(event_id:id, session_code:h[:session_code])

      if sessions.length > 0

        session  = sessions.first

        case template
        when 'date_tags'
          h[:session_tags] = add_date_tags(session, h[:session_tags], top_level_tag)
        when 'session_location_tags'
          type_id          = MapType.where(map_type:'Session Map').first.id
          event_maps       = EventMap.where(event_id:id, map_type_id:type_id).pluck(:name)
          h[:session_tags] = add_session_location_tags(session, h[:session_tags], top_level_tag, event_maps)
        else
          raise 'template invalid'
        end
      else
        raise "Session with code #{h[:session_code]} does not exist."
      end
    end
  end

  def remove_tags_for_sessions_template(template, complete_tags_array, top_level_tag)

    complete_tags_array.each do |h|

      sessions = Session.where(event_id:id, session_code:h[:session_code])

      if sessions.length > 0

        session  = sessions.first

        case template
        when 'date_tags'
          h[:session_tags] = remove_date_tags(h[:session_tags], top_level_tag)
        when 'session_location_tags'
          type_id          = MapType.where(map_type:'Session Map').first.id
          event_maps       = EventMap.where(event_id:id, map_type_id:type_id).pluck(:name)
          h[:session_tags] = remove_location_tags(h[:session_tags], top_level_tag, event_maps)
        else
          raise 'template invalid'
        end
      else
        raise "Session with code #{h[:session_code]} does not exist."
      end
    end
  end

  def add_exhibitor_location_tags(exhibitor, tag_set, top_level_tag, event_maps)
    event_map = exhibitor.event_map.name
    booth     = exhibitor.location_mapping.name
    tag_set   = remove_location_tags(tag_set, top_level_tag, event_maps)
    if top_level_tag
      tag_set << [top_level_tag, event_map, booth]
    else
      tag_set << [event_map, booth]
    end
  end

  def add_tags_for_exhibitors_template(template, complete_tags_array, top_level_tag)

    complete_tags_array.each do |h|

      exhibitors = Exhibitor.where(event_id:id, company_name:h[:company_name])

      if exhibitors.length > 0

        exhibitor  = exhibitors.first

        case template
        when 'exhibitor_location_tags'
          type_id            = MapType.where(map_type:'Exhibitor Map').first.id
          event_maps         = EventMap.where(event_id:id, map_type_id:type_id).pluck(:name)
          h[:exhibitor_tags] = add_exhibitor_location_tags(exhibitor, h[:exhibitor_tags], top_level_tag, event_maps)
        else
          raise 'template invalid'
        end
      else
        raise "Exhibitor with company named #{h[:company_name]} does not exist."
      end
    end
  end

  def remove_tags_for_exhibitors_template(template, complete_tags_array, top_level_tag)

    complete_tags_array.each do |h|

      exhibitors = Exhibitor.where(event_id:id, company_name:h[:company_name])

      if exhibitors.length > 0

        exhibitor  = exhibitors.first

        case template
        when 'date_tags'
          h[:exhibitor_tags] = remove_date_tags(h[:exhibitor_tags], top_level_tag)
        when 'exhibitor_location_tags'
          type_id            = MapType.where(map_type:'Exhibitor Map').first.id
          event_maps         = EventMap.where(event_id:id, map_type_id:type_id).pluck(:name)
          h[:exhibitor_tags] = remove_location_tags(h[:exhibitor_tags], top_level_tag, event_maps)
        else
          raise 'template invalid'
        end
      else
        raise "Exhibitor with company named #{h[:company_name]} does not exist."
      end
    end
  end

  ###

  def update_all_tags(template, options = {})

    session_templates   = ['date_tags', 'session_location_tags']
    exhibitor_templates = ['exhibitor_location_tags']

    we_are_removing_only = options.fetch(:we_are_removing_only, false)

    top_level_tag       = options.fetch(:top_level_tag, false)

    if session_templates.include? template

      tag_type_id         = TagType.session_type_id
      complete_tags_array = get_array_of_session_codes_and_their_tags(id)

      unless we_are_removing_only
        add_tags_for_sessions_template(template, complete_tags_array, top_level_tag)
      else
        remove_tags_for_sessions_template(template, complete_tags_array, top_level_tag)
      end

      remove_session_tags(tag_type_id)
      add_tags_for_all_sessions(complete_tags_array, id, tag_type_id)
    elsif exhibitor_templates.include? template

      tag_type_id         = TagType.exhibitor_type_id
      complete_tags_array = get_array_of_company_names_and_their_tags(id)

      unless we_are_removing_only
        add_tags_for_exhibitors_template(template, complete_tags_array, top_level_tag)
      else
        remove_tags_for_exhibitors_template(template, complete_tags_array, top_level_tag)
      end

      remove_exhibitor_tags(tag_type_id)
      add_tags_for_all_exhibitors(complete_tags_array, id, tag_type_id)
    else
      false
    end
    true
  end
end