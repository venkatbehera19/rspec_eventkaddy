class CustomListsController < ApplicationController

  layout :set_layout
  load_and_authorize_resource
  helper_method :diyContentEnabled, :getDiyMobileWebSettings
  before_action :setDiyLayoutVariables, :except => [:mobile_data]

  def mobile_data

    @empty_data = "[]"

    if params[:event_id]
      @custom_lists = CustomList.select('custom_list_items.id AS item_id,home_button_id,custom_lists.name AS custom_list_name,custom_lists.description AS custom_list_description,
        custom_list_types.name AS custom_list_type_name,custom_list_items.content AS item_content, custom_list_items.title AS item_title,
        custom_list_items.position,event_files.path AS file_url').where('
        custom_lists.event_id=? AND custom_list_items.id > ?',params[:event_id],params[:record_start_id]).joins('
        LEFT OUTER JOIN event_files ON custom_lists.image_event_file_id=event_files.id
        JOIN custom_list_types ON custom_lists.custom_list_type_id=custom_list_types.id
        JOIN custom_list_items ON custom_list_items.custom_list_id=custom_lists.id').order('item_id ASC').limit(100)

      if @custom_lists.length > 0
        render :json => @custom_lists.to_json, :callback => params[:callback]
      else
        render :json => @empty_data, :callback => params[:callback]
      end
    end
  end

  def show
    @custom_list       = CustomList.find params[:id]
    @custom_list_items = CustomListItem
      .where(custom_list_id: @custom_list.id)
      .order('position ASC')
  end

  def update
    @custom_list       = CustomList.find params[:id]
    @custom_list_items = CustomListItem
      .where(custom_list_id: @custom_list.id)
      .order('position ASC')
    
    respond_to do |format|
      if @custom_list.update!(custom_list_params)
        format.html { redirect_to("/custom_lists/#{@custom_list.id}", :notice => 'Custom List was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @custom_list.errors, :status => :unprocessable_entity }
      end
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

  def custom_list_params
    params.require(:custom_list).permit(:event_id, :home_button_id, :image_event_file_id, :name, :description, :custom_list_type_id)
  end

end