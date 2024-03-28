# This module exists to be mixed into controllers like Tags, ExhibitorPortals
# and SpeakerPortals, to give them access to some generic routes for editting
# preset event tags.

# A #tag_type_name and #model_id will need to be supplied by the parent class
# for the mixed in routes to work. This allows the controller to decide for
# itself how these attributes are acquired, which as I found out is very
# different between the generic TagsController and ExhibitorPortalsController.

module SimpleTagsRoutes

  def edit_tags
    # raise if not user_match_model
    @controller_name = controller_name
    @tag_type_name   = tag_type_name # has to be fed into update_tags
    @preset_tagsets  = get_preset_tags(@tag_type_name).map {|s| s.join(' -> ')}
    @model           = get_model tag_type_name, model_id

    @tagsets = @model.tags.map do |leaf_tag|
      (( leaf_tag.get_all_parents.map(&:name) ) << leaf_tag.name).join(' -> ')
    end
    render 'tags/edit_tags'
  end

  def update_tags
    # I get validation model belongs to the user for free because
    # model_id in the portals is based on the user method, not the parameters
    # For a client, the get_model method raises if the event_id is wrong
    model           = get_model tag_type_name, model_id
    preset_tagsets  = get_preset_tags(tag_type_name).map {|s| s.join(' -> ')}

    # don't allow users to make up their own tags; since this is for the exhibitor
    # portal with a lot of unknown users, this is just a small protection against
    # profanity or other kinds of mischief.
    (params[:tagsets] || []).each do |tagset|
      raise "Invalid tagset #{tagset.inspect}" unless preset_tagsets.include? tagset
    end

    model.update_tags(
      (params[:tagsets] || []).map {|s| s.split " -> " },
      tag_type_name
    )

    tagsets = model.tags.map do |leaf_tag|
      (( leaf_tag.get_all_parents.map(&:name) ) << leaf_tag.name).join(' -> ')
    end

    tag_update_redirect model.id
  end

  private

  def tag_update_redirect model_id
    params_string = controller_name == 'tags' ? "/#{params[:tag_type_name]}/#{model_id}" : ""
    respond_to do |f|
      f.html {
        redirect_to(
          "/#{controller_name}/edit_tags#{params_string}",
          :notice => 'Updated Tags'
        )
      }
    end
  end

  def get_model tag_type_name, model_id
    m = case tag_type_name
        when 'session', 'session-audience'
          Session.find model_id
        when 'exhibitor'
          Exhibitor.find model_id
        when 'attendee'
          Attendee.find model_id
        else
          raise 'Invalid tag type requested.'
        end
    raise "Tried to access model for another event." if m.event_id != session[:event_id]
    m
  end

  def get_preset_tags tag_type_name
    event       = Event.find session[:event_id]
    tag_type_id = TagType.where(name: tag_type_name).first.id.to_s
    tsh         = event.tag_sets_hash
    tsh && tsh[ tag_type_id ] || []
  end

end
