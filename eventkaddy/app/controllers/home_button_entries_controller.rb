class HomeButtonEntriesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  def index
    @home_button_entries = HomeButtonEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @home_button_entries }
    end
  end

  def show
    @home_button_entry = HomeButtonEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @home_button_entry }
    end
  end

  def new
    @home_button_entry       = HomeButtonEntry.new
    @home_button_entry_types = HomeButtonEntryType.all
    @home_button_group_id    = params[:home_button_group_id]
    @home_button_entries     = HomeButtonEntry.where(group_id:@home_button_group_id).order("position ASC")
    type_id                  = EventFileType.where(name:"home_button_entry_image").first.id
    @event_files             = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @home_button_entry }
    end
  end

  def edit
    @home_button_entry_types = HomeButtonEntryType.all
    @home_button_entry       = HomeButtonEntry.find(params[:id])
    @home_button_group_id    = @home_button_entry.group_id
    @home_button_entries     = HomeButtonEntry.where(group_id:@home_button_group_id).order("position ASC")
    type_id                  = EventFileType.where(name:"home_button_entry_image").first.id
    @event_files             = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id])
  end

  def create
    #update gallery
    if (params[:event_file]!='' && params[:event_file]!=nil) then
        @event_file          = EventFile.new
        @event_file.event_id = session[:event_id]
        @event_file.entryImage(params, "home_button_entry_image")

    respond_to do |format|
      if @event_file.save

        format.html { redirect_to('/home_button_entries/new', :notice => 'Entry was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end

    else
      @home_button_entries = HomeButtonEntry.where(group_id:params[:home_button_entry][:group_id])
      @home_button_entry   = HomeButtonEntry.new(home_button_entry_params)
      event_id             = session[:event_id]
      #update positions
      unless params[:json].blank?
        json                 = JSON.parse(params[:json])
        json.each do |entry|
          if entry["id"]!="new"
            @home_button_entries.where(id:entry["id"].to_i).first.update_columns(:position => entry["order"].to_i)
          else
            @home_button_entry.position = entry["order"].to_i
          end
        end
      end

      @home_button_entry.uploadIcon(params,event_id)

      respond_to do |format|
        if @home_button_entry.save(validate: false)

          @home_button_group = HomeButtonGroup.find(@home_button_entry.group_id)
  #        format.html { redirect_to("/home_button_groups/#{@home_button_entry.group_id}", :notice => 'Home button entry was successfully created.') }
          format.html { redirect_to("/home_button_groups/#{@home_button_group.id}", :notice => 'Home button entry was successfully created.') }
          format.xml  { render :xml => @home_button_entry, :status => :created, :location => @home_button_entry }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @home_button_entry.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def update
    #update gallery
    if (params[:event_file]!='' && params[:event_file]!=nil) then
      @event_file            = EventFile.new
      @event_file.event_id   = session[:event_id]
      @event_file.entryImage(params, "home_button_entry_image")

      respond_to do |format|
        if @event_file.save

          format.html { redirect_to('/home_button_entries/new', :notice => 'Entry was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
        end
      end

    else

      @home_button_entries = HomeButtonEntry.where(group_id:params[:home_button_entry][:group_id])
      @home_button_entry   = HomeButtonEntry.find(params[:id])
      event_id             = session[:event_id]

      #update positions
      unless params[:json].blank?
        json                 = JSON.parse(params[:json])
        json.each do |entry|
            @home_button_entries.where(id:entry["id"].to_i).first.update_columns(:position => entry["order"].to_i)
        end
      end

    	@home_button_entry.uploadIcon(params,event_id)

      respond_to do |format|
        @home_button_entry.attributes = home_button_entry_params
        if @home_button_entry.save(validate: false)

          @home_button_group = HomeButtonGroup.find(@home_button_entry.group_id)

  #        format.html { redirect_to("/home_button_groups/#{@home_button_entry.group_id}", :notice => 'Home button entry was successfully updated.') }
          format.html { redirect_to("/home_button_groups/#{@home_button_group.id}", :notice => 'Home button entry was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @home_button_entry.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def destroy

    @home_button_group = HomeButtonGroup.find(@home_button_entry.group_id)
    @home_button_entry = HomeButtonEntry.find(params[:id])
    @home_button_entry.destroy

    respond_to do |format|
      format.html { redirect_to("/home_button_groups/#{@home_button_entry.group_id}") }
      #format.html { redirect_to("/home_button_groups/category/#{@home_button_group.name}") }
      format.xml  { head :ok }
    end
  end

  def ajax_data
    type_id = EventFileType.where(name:"home_button_entry_image").first.id

    if EventFile.where(event_file_type_id:type_id).length > 0
      render :plain => EventFile.where(event_file_type_id:type_id).last.path
      return
    end
  end

  private

    def home_button_entry_params
      params.require(:home_button_entry).permit(:group_id, :event_file_id, :render_url, :name, :icon_entry, :content, :position, :home_button_entry_type_id)
    end

end