class TagsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  # adds edit_tags and update_tags for preset tags
  include SimpleTagsRoutes

  # just an api that should return JSON for our tag edit
  # will give all the tags possible for the model, and their
  # status of whether they are selected or not
  #
  # This was going to be for a graphical tag interface; might still be
  # used later but I'm doing something simpler now
  #
  # def tags_for_model
  #   tag_type = TagType.where(id: params[:tag_type] ).first
  #   # could be extracted as Tag#get_model_id_for_tag_type
  #   model_id = case tag_type && tag_type.name
  #              when 'session', 'session-audience'
  #                Session.find params[:model_id]
  #              when 'exhibitor'
  #                Exhibitor.find params[:model_id]
  #              when 'attendee'
  #                Attendee.find params[:model_id]
  #              else
  #                raise 'Invalid tag type requested.'
  #              end
  #   tags = [] # some query here
  #   render :json => tags
  # end

  def edit
    @tag = Tag.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @tag = Tag.find(params[:id])
    @tag.name = params[:tag][:name]
    if @tag.save
      redirect_to '/tags', notice: "Tags updated successfully!"
    else
      redirect_to '/tags', notice: "Something went wwrong"
    end
  end

  def abandoned_tags
    @abandoned_tags = Tag.unused_leaf_tags_for_event( session[:event_id] )
    render layout: 'dashboard'
  end

  def destroy
    Tag.find(params[:id]).remove_self_and_parents_without_children
    redirect_back fallback_location: root_path
  end

  private

  # for benefit of mixed in SimpleTagsRoutes
  def tag_type_name
    params[:tag_type_name]
  end

  # for benefit of mixed in SimpleTagsRoutes
  def model_id
    params[:model_id]
  end
  
end