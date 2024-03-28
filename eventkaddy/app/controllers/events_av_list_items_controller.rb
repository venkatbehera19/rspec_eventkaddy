class EventsAvListItemsController < ApplicationController
  layout 'settings'
  load_and_authorize_resource

  # on select page, jquery post to create new ones
  def create
    if AvListItem.where(name: params[:name]).blank?
      item = AvListItem.create(name: params[:name])
      EventsAvListItem.where(event_id:session[:event_id],av_list_item_id:item.id).first_or_create # might as well create it right away in case they get confused about submitting
      render :json => { status: true, message: "Successfully created #{params[:name]}", name: item.name, id: item.id }
    else
      render :json => { status: false, message: "AV Request Item with name #{params[:name]} already exists." }
    end
  end

  def select
    @av_list_item            = AvListItem.new
    @av_list_items           = AvListItem.all.sort {|a, b| a.name <=> b.name } # order(:name) for some reason is finnicky
    @events_av_list_item_ids = EventsAvListItem.where(event_id: session[:event_id]).pluck(:av_list_item_id)
  end

  def update_select
    params[:av_list_item_ids].each do |id|
      EventsAvListItem.where(event_id:session[:event_id],av_list_item_id:id).first_or_create
    end
    EventsAvListItem.where('event_id=? AND av_list_item_id NOT IN(?)', session[:event_id], params[:av_list_item_ids]).destroy_all
    respond_to do |f|
      f.html {
        redirect_to(
          "/settings/speaker_portal",
          :notice => "Updated AV Request Items (#{EventsAvListItem.select('name').where(event_id: session[:event_id]).joins(:av_list_item).map(&:name).join(', ')})"
        )
      }
    end
  end

end