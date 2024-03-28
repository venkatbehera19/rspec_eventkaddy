class TabsController < ApplicationController

  layout "subevent_2013"

  def index
    @tabs = Tab.where(event_id:session[:event_id])
    respond_to do |format|
      format.html
    end
  end

  # def new
  #   @tab = Tab.new
  #   respond_to do |format|
  #     format.html
  #   end
  # end

  # def create
  #   @tab = Tab.new(tab_params)
  #   respond_to do |format|
  #     if @tab.save
  #       format.html { redirect_to("/event_settings/edit_event_tabs", :notice => 'Tab successfully created.') }
  #     else
  #       format.html { render :action => "new" }
  #     end
  #   end
  # end

  def edit
    @tab = Tab.find(params[:id])
  end

  def update
    @tab = Tab.find(params[:id])
    respond_to do |format|
      if @tab.update!(tab_params)
        # two different edit pages use the same update method; so here's a solution to that
        # legacy issue. A more involved solution would be to get the edit pages to use the 
        # same routes and switch type based on a parameter
        if @tab.tab_type.portal == 'attendee'
          # this is for editing the registration_portal tabs
          format.html { redirect_to("/settings/registration_portal_settings", :notice => 'Tab successfully updated.') }
        else  
          type = @tab.tab_type.portal == 'speaker' ? "speaker_" : @tab.tab_type.portal == "attendee_portal" ? "attendee_" : "exhibitor_"
          format.html { redirect_to("/settings/#{type}portal", :notice => 'Tab successfully updated.') }
        end
      else
        format.html { render :action => "edit" }
      end
    end

  end

  # def destroy
  #   @tab = Tab.find(params[:id])
  #   @tab.delete
  #   respond_to do |format|
  #       format.html { redirect_to("/event_settings/edit_event_tabs", :notice => 'Tab successfully deleted.') }
  #   end
  # end

  private

  def tab_params
    params.require(:tab).permit(:event_id, :tab_type_id, :name, :enabled, :order, :header_text, :footer_text)
  end

end