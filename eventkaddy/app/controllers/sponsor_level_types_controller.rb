class SponsorLevelTypesController < ApplicationController
  # GET /sponsor_level_types
  # GET /sponsor_level_types.xml
  layout 'subevent_2013'
  load_and_authorize_resource
  
  
  def index
    @is_super_admin = current_user.role? 'SuperAdmin'
    @event = Event.find(session[:event_id])
    @event_sponsor_level_types = EventSponsorLevelType.where(event_id: session[:event_id]).order(:rank).includes(:sponsor_level_type)
    # SponsorLevelType.joins(:event_sponsor_level_types)
    #   .where("event_sponsor_level_types.event_id = ?", @event.id).order("event_sponsor_level_types.rank")
    @sponsor_level_types = SponsorLevelType.where.not(id: @event_sponsor_level_types.pluck(:sponsor_level_type_id))

    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @sponsor_level_types }
    end
  end

  # POST /sponsor_level_types
  # POST /sponsor_level_types.xml
  def create
    @sponsor_level_type = SponsorLevelType.new(sponsor_level_type_params)
    raise "Sponsor level type with name #{sponsor_level_type_params[:sponsor_type]} already exist." unless SponsorLevelType.where(sponsor_type: sponsor_level_type_params[:sponsor_type]).blank?
    @sponsor_level_type.save!
    # These steps adds the newly created sponsor level type to the event sponsor level type table as well
    EventSponsorLevelType.create!(event_id: session[:event_id], sponsor_level_type_id: @sponsor_level_type.id)
    redirect_to sponsor_level_types_path
  end

  # PUT /sponsor_level_types/1
  # PUT /sponsor_level_types/1.xml
  def update
    @sponsor_level_type = SponsorLevelType.find(params[:id])

    respond_to do |format|
      if @sponsor_level_type.update!(sponsor_level_type_params)
        format.html { redirect_to(@sponsor_level_type, :notice => 'Sponsor level type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sponsor_level_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_event_sponsor_level_types
    event_id = session[:event_id]
    sponsor_level_types = params[:sponsor_level_types]
    sponsor_level_types.each do |key, sponsor_level_type|
      event_sponsor_level_type = EventSponsorLevelType.where(event_id: event_id, sponsor_level_type_id: sponsor_level_type["sponsor_type_id"]).first_or_create
      event_sponsor_level_type.update!(rank: sponsor_level_type["ranking_position"].to_i)
    end
    render json: {notice: "ok"}, status: 200
  end

  def remove_from_event_sponsor_level_type
    @event_sponsor_level_type = EventSponsorLevelType.where(event_id: session[:event_id], sponsor_level_type_id: params[:sponsor_level_type_id]).first
    if @event_sponsor_level_type.medal_image 
      UploadMedalImage.new({cloud_storage_type: @event_sponsor_level_type.medal_image.cloud_storage_type, file_asset: @event_sponsor_level_type.medal_image}).delete_medal
    end
    @event_sponsor_level_type.destroy
    render json: {notice: 'ok'}, status: 200
  end

  def add_medal_image
    if params[:scope_level].eql?('event_level')
      @event_sponsor_level_type = EventSponsorLevelType
      .where(event_id: session[:event_id], sponsor_level_type_id: params[:sponsor_level_id]).first
      medal_image = @event_sponsor_level_type.medal_image ? @event_sponsor_level_type.medal_image :
        @event_sponsor_level_type.build_medal_image(mime_type: params[:sponsor_medal].content_type)
      medal_image.save_medal_image params[:sponsor_medal]
      render json: {data: {id: @event_sponsor_level_type.sponsor_level_type_id,
        scope: 'event_level', url: medal_image.get_aws_url}}
    else
      @sponsor_level_type = SponsorLevelType.find(params[:sponsor_level_id])
      medal_image = @sponsor_level_type.medal_image ? @sponsor_level_type.medal_image :
        @sponsor_level_type.build_medal_image(mime_type: params[:sponsor_medal].content_type)
      medal_image.save_medal_image params[:sponsor_medal]
      render json: {data: {id: @sponsor_level_type.id, scope: 'global_level', url: medal_image.get_aws_url}}
    end
  end

  private

  def sponsor_level_type_params
    params.require(:sponsor_level_type).permit(:sponsor_type, :id, :scope, :photo)
  end

end