class CustomListItemsController < ApplicationController

  layout :set_layout
  load_and_authorize_resource
  helper_method :diyContentEnabled, :getDiyMobileWebSettings
  before_action :setDiyLayoutVariables

  def new
    @custom_list_item  = CustomListItem.new
    @custom_list_items = CustomListItem.where(custom_list_id:params[:custom_list_id]).order('position ASC')
    @custom_list_id    = params[:custom_list_id]

    type_id            = EventFileType.where(name:"home_button_entry_image").first.id
    @event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id])

  end

  def create
    #update gallery
    if (params[:event_file]!='' && params[:event_file]!=nil) then
        @event_file          = EventFile.new
        @event_file.event_id = session[:event_id]
        @event_file.entryImage(params, "home_button_entry_image")

    respond_to do |format|
      if @event_file.save

        format.html { redirect_to('/custom_list_items/new', :notice => 'Entry was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end

    else
      @custom_list_items         = CustomListItem.where(custom_list_id:params[:custom_list_item][:custom_list_id])
      @custom_list_item          = CustomListItem.new(custom_list_item_params)
      event_id                   = session[:event_id]
      @custom_list_item.event_id = event_id


      @custom_list_items.createAndUpdatePositions(params[:json],@custom_list_item) unless params[:json].blank?

      #@custom_list_item.uploadIcon(params,event_id)

      respond_to do |format|
        if @custom_list_item.save

          format.html { redirect_to("/custom_lists/#{@custom_list_item.custom_list.id}", :notice => 'Custom list item was successfully created.') }
          format.xml  { render :xml => @custom_list_item, :status => :created, :location => @custom_list_item }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @custom_list_item.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

	def edit
    @custom_list_item  = CustomListItem.find(params[:id])
    @custom_list_items = CustomListItem.where(custom_list_id:@custom_list_item.custom_list_id).order('position ASC')
    @custom_list_id    = @custom_list_item.custom_list.id

		type_id            = EventFileType.where(name:"home_button_entry_image").first.id
		@event_files       = EventFile.where(event_file_type_id:type_id,event_id:session[:event_id])

	end

	def update
    #update gallery
    if (params[:event_file]!='' && params[:event_file]!=nil) then
      @event_file            = EventFile.new
      @event_file.event_id   = session[:event_id]
      @event_file.entryImage(params, "home_button_entry_image")

      respond_to do |format|
        if @event_file.save

          format.html { redirect_to('/custom_list_items/new', :notice => 'Item was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
        end
      end

    else

			@custom_list_items = CustomListItem.where(custom_list_id:params[:custom_list_item][:custom_list_id])
			@custom_list_item  = CustomListItem.find(params[:id])
			@custom_list       = CustomList.find(@custom_list_item.custom_list_id)
			event_id           = session[:event_id]

      #update positions

      @custom_list_items.updatePositions(params[:json]) unless params[:json].blank?

      @custom_list_item.uploadIcon(params,event_id)

      respond_to do |format|
        if @custom_list_item.update!(custom_list_item_params)

          format.html { redirect_to("/custom_lists/#{@custom_list.id}", :notice => 'Custom list item was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @custom_list_item.errors, :status => :unprocessable_entity }
        end
      end
    end
	end

	def destroy
    custom_list      = CustomList.find(@custom_list_item.custom_list_id)
    custom_list_item = CustomListItem.find(params[:id])
    custom_list_item.updatePositionsAndDestroy(custom_list.custom_list_items)

    respond_to do |format|
      format.html { redirect_to("/custom_lists/#{custom_list.id}") }
      format.xml  { head :ok }
    end
	end

  def ajax_data
    type_id = EventFileType.where(name:"home_button_entry_image").first.id

    if EventFile.where(event_file_type_id:type_id).length > 0
      event_image = EventFile.where(event_file_type_id:type_id).last
      render :json => { path: event_image.path, id: event_image.id}
    end
  end


	private

  def set_layout
    if current_user.role? :diyclient then
      'diy_features'
    else
      'subevent_2013'
    end
  end

  def custom_list_item_params
    params.require(:custom_list_item).permit(:event_id, :custom_list_id, :title, :content, :position)
  end

end