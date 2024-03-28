module ProgramFeedsHelper
  def program_feed_audience_tags(event_id)
    tag = Tag.includes(:children).where(event_id: event_id, tag_type_id: TagType.session_audience_type_id, parent_id: 0)
    tag
  end

  def program_feed_session_tags(event_id)
    tag = Tag.includes(:children).where(event_id: event_id, tag_type_id: TagType.session_type_id, parent_id: 0)
    tag
  end

  def program_feed_exhibitor_tag(event_id)
    tag = Tag.includes(:children).where(event_id: event_id, tag_type: TagType.exhibitor_type_id, parent_id: 0)
    tag
  end

  def get_family(tag)
    family = find_family(tag, [])
  end

  def find_family(tag, arr)
    hash_l = {}
    hash_l[:id] = tag.id
    hash_l[:name] = tag.name
    unless tag.leaf
      hash_l[:child] = find_children(tag.children)
    end
    arr << hash_l
    arr
  end

  def find_children(tag)
    arr = []
    tag.each do |t|
      hash_ll = {}
      hash_ll[:id] = t.id
      hash_ll[:name] = t.name
      unless t.leaf
        hash_ll[:child] = find_children(t.children)
      end
      arr << hash_ll
    end
    arr
  end

  def make_html(family, parent_name)
    str = []
    family.each do |member|
      if member[:child].present?
        member[:child].each do |sub_member|
          str << html_ul(sub_member, parent_name)
        end
      end
    end
    str
  end

  def html_ul(child, parent_name = nil)
  "<li><label class='labels'><a>#{child[:child].present? ? '': "<input type='checkbox' class='filters_tag align-middle' id='filter_tag_#{child[:id]}' data-class-name='#{child[:name]}' data-parent-name='#{parent_name}'>"}<span class='pl-1'>#{child[:name]}</span></a></label>#{child[:child].present? ? "<ul><li><label class='labels'><a><input type='checkbox' class='filters_tag align-middle' id='filter_tag_#{child[:id]}' data-class-name='#{child[:name]}' data-parent-name='#{parent_name}'><span class='pl-1'>All</span></a></label>#{child[:child].map{|sub_child| html_ul(sub_child, child[:name])}.join}</ul>" : ''}</li>"
  end

  def twelve_hour_format?(event_id)
  	@settings&.program_feed_twelve_hour_format
  end

  def get_sessions_keywords(event_id)
    #Session.where(event_id: event_id).pluck(:keyword).map{|key| key.split(',')}.flatten.uniq
    keywords = Session.where(event_id: event_id).pluck(:keyword).map do |key|
      if key.present?
        key.split(',')
      end
    end
    keywords = keywords.flatten.compact.uniq
    keywords
  end

  def get_sponsor_logo(sponsor)
    url = nil
    event_file_id = sponsor.logo_event_file_id
    event_file = EventFile.find_by(id: event_file_id)
    url = event_file.return_public_url["url"] if event_file.present?
  end

  def sponsor_level_types
    sponsor_level_types = SponsorLevelType.all
  end

  def session_favorite(session_id)
    @sessions_attendees_ids.include? session_id.to_s
  end

  def exhibitor_favorite(exhibitor_id)
    @exhibitor_attendees_ids.include? exhibitor_id
  end
end