class HomeButtonGroupsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource


  def mobile_data

   @empty_data = "[]"

	if (params[:event_id]) then
		@home_button_groups = HomeButtonGroup.select('home_button_groups.*,event_files.path AS file_url').where("home_button_groups.event_id= ? AND home_button_groups.id > ?",params[:event_id],params[:record_start_id]).joins('
		LEFT OUTER JOIN event_files ON home_button_groups.event_file_id=event_files.id').order('home_button_groups.id ASC').limit(100)

		if (@home_button_groups.length > 0) then
			render :json => @home_button_groups.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end

    end

  end


  def mobile_data_extras

   @empty_data = "[]"

	if (params[:event_id]) then
		@home_button_entries = HomeButtonGroup.select('home_button_entries.*, home_button_entry_types.name AS entry_type').joins('
		JOIN home_button_entries ON home_button_entries.group_id=home_button_groups.id
		LEFT JOIN home_button_entry_types ON home_button_entries.home_button_entry_type_id=home_button_entry_types.id
		').where("home_button_groups.event_id= ? AND home_button_entries.id > ? AND (home_button_groups.icon_button LIKE ? OR home_button_groups.icon_button LIKE ?)",params[:event_id],params[:record_start_id],'%extras.png%','%Extras.png%').order('home_button_entries.id ASC').limit(100)

		if (@home_button_entries.length > 0) then
			render :json => @home_button_entries.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end


    end

  end

  def mobile_data_videos

   @empty_data = "[]"

	if (params[:event_id]) then
		@home_button_entries = HomeButtonGroup.select('home_button_entries.*').joins('
		JOIN home_button_entries ON home_button_entries.group_id=home_button_groups.id
		').where("home_button_groups.event_id= ? AND home_button_entries.id > ? AND (home_button_groups.icon_button LIKE ? OR home_button_groups.icon_button LIKE ?)",params[:event_id],params[:record_start_id],'%videos.png%','%Videos.png%').order('home_button_entries.id ASC').limit(100)

		if (@home_button_entries.length > 0) then
			render :json => @home_button_entries.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end

    end

  end

  def mobile_data_socials

   @empty_data = "[]"

	if (params[:event_id]) then
		@home_button_entries = HomeButtonGroup.select('home_button_entries.*').joins('
		JOIN home_button_entries ON home_button_entries.group_id=home_button_groups.id
		').where("home_button_groups.event_id= ? AND home_button_entries.id > ? AND (home_button_groups.icon_button LIKE ? OR home_button_groups.icon_button LIKE ?)",params[:event_id],params[:record_start_id],'%Social.png%','%social.png%').order('home_button_entries.id ASC').limit(100)

		if (@home_button_entries.length > 0) then
			render :json => @home_button_entries.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end


    end

  end

  def index

	if (session[:event_id]) then
		@home_button_groups = HomeButtonGroup.where(event_id:session[:event_id]).order('position ASC')

	    respond_to do |format|
	      format.html #{ render :json => @exhibitors } # index.html.erb
	      format.xml  { render :xml => @home_button_groups }
	      format.json { render :json => @home_button_groups.to_json, :callback => params[:callback] } #render :json => @exhibitors }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  def show


    @admin_view=true
	 @home_button_group = HomeButtonGroup.find(params[:id])
	 @home_button_entries = HomeButtonEntry.where('group_id= ?',@home_button_group.id).order('home_button_entry_type_id, position')

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @home_button_group }
    end


  end

  def show_category_entries

	logger.info "TEST params id: #{params[:id]}"

	 @home_button_entries = HomeButtonEntry.joins('JOIN home_button_groups ON home_button_entries.group_id=home_button_groups.id').where('home_button_groups.name= ? AND home_button_groups.event_id= ?',params[:entry_category],session[:event_id])
    @home_button_group = HomeButtonGroup.where('home_button_groups.name= ? AND home_button_groups.event_id= ?',params[:entry_category],session[:event_id]).limit(1)[0]

	 respond_to do |format|
      format.html # show_category_entries.html.erb

    end


  end

  def new
	@home_button_group  = HomeButtonGroup.new
	@home_button_groups = HomeButtonGroup.where(event_id:session[:event_id]).order('position ASC')

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @home_button_group }
    end
  end

  # GET /home_button_groups/1/edit
  def edit
	@home_button_group  = HomeButtonGroup.find(params[:id])
	@home_button_groups = HomeButtonGroup.where(event_id:session[:event_id]).order('position ASC')
  end

  def create

  @home_button_groups         = HomeButtonGroup.where(event_id:session[:event_id])
  @home_button_group          = HomeButtonGroup.new(home_button_group_params)
  @home_button_group.event_id = session[:event_id]
  event_id                    = session[:event_id]

  #update positions
  unless params[:json].blank?
  	json                        = JSON.parse(params[:json])
  	json.each do |group|
  		if group["id"]!="new"
  			@home_button_groups.where(id:group["id"].to_i).first.update_columns(:position => group["order"].to_i)
  		else
  			@home_button_group.position = group["order"].to_i
  		end
  	end
  end

	@home_button_group.uploadIcon(params,event_id)

    respond_to do |format|
      if @home_button_group.save
        format.html { redirect_to(@home_button_group, :notice => 'Home button group was successfully created.') }
        format.xml  { render :xml => @home_button_group, :status => :created, :location => @home_button_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @home_button_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

  @home_button_groups = HomeButtonGroup.where(event_id:session[:event_id])
  @home_button_group  = HomeButtonGroup.find(params[:id])
  event_id            = session[:event_id]

  #update positions
  unless params[:json].blank?
  	json = JSON.parse(params[:json])
  	json.each do |group|
  		@home_button_groups.where(id:group["id"].to_i).first.update!(:position => group["order"].to_i)
  	end
  end


	@home_button_group.uploadIcon(params,event_id)

    respond_to do |format|
      if @home_button_group.update!(home_button_group_params)
        format.html { redirect_to(@home_button_group, :notice => 'Home button group was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @home_button_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @home_button_group = HomeButtonGroup.find(params[:id])
    @home_button_group.destroy

    respond_to do |format|
      format.html { redirect_to(home_button_groups_url) }
      format.xml  { head :ok }
    end
  end

  private

  def home_button_group_params
    params.require(:home_button_group).permit(:event_id, :event_file_id, :name, :icon_button, :position)
  end

end