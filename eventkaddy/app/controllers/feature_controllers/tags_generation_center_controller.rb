class TagsGenerationCenterController < ApplicationController
  # load_and_authorize_resource
  layout 'subevent_2013'

  def tag_generation_action_and_rediect(template, options={})

    respond_to do |format|
      if Event.find(session[:event_id]).update_all_tags(template, options)
        format.html {redirect_to("/tags_generation_center", :notice => "Successfully updated tags.")}
      else
        format.html {redirect_to("/tags_generation_center", :alert => "An error occured before the tag generation could be completed.")}
      end
    end
  end

  def tags_generation_center
    @event = Event.find(session[:event_id])
  end

  def generate_date_tags
    top_level_tag = params[:date_header]
    tag_generation_action_and_rediect('date_tags', :top_level_tag => top_level_tag)
  end

  def generate_date_tags_without_a_top_tag
    tag_generation_action_and_rediect('date_tags')
  end

  # def remove_date_tags_without_a_top_tag
  #   tag_generation_action_and_rediect('date_tags', :we_are_removing_only => true)
  # end

  def remove_date_tags
    top_level_tag = params[:date_header_to_remove]
    tag_generation_action_and_rediect('date_tags', :top_level_tag => top_level_tag, :we_are_removing_only => true)
  end

  # def generate_session_location_tags
  #   top_level_tag = params[:session_location_header]
  #   tag_generation_action_and_rediect('session_location_tags', :top_level_tag => top_level_tag)
  # end

  def generate_session_location_tags_without_a_top_tag
    tag_generation_action_and_rediect('session_location_tags')
  end

  def remove_session_location_tags_without_a_top_tag
    tag_generation_action_and_rediect('session_location_tags', :we_are_removing_only => true)
  end

  def remove_session_location_tags
    top_level_tag = params[:session_location_header_to_remove]
    tag_generation_action_and_rediect('session_location_tags', :top_level_tag => top_level_tag, :we_are_removing_only => true)
  end

  def generate_exhibitor_location_tags
    top_level_tag = params[:exhibitor_location_header]
    tag_generation_action_and_rediect('exhibitor_location_tags', :top_level_tag => top_level_tag)
  end

  def generate_exhibitor_location_tags_without_a_top_tag
    tag_generation_action_and_rediect('exhibitor_location_tags')
  end

  def remove_exhibitor_location_tags_without_a_top_tag
    tag_generation_action_and_rediect('exhibitor_location_tags', :we_are_removing_only => true)
  end

  def remove_exhibitor_location_tags
    top_level_tag = params[:exhibitor_location_header_to_remove]
    tag_generation_action_and_rediect('exhibitor_location_tags', :top_level_tag => top_level_tag, :we_are_removing_only => true)
  end

end