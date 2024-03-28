class ScriptsController < ApplicationController

  load_and_authorize_resource
  layout 'subevent_2013'
  
  def index
    @event  = Event.find(session[:event_id])
    @scripts = Script.where(event_id:@event.id)
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def show
    @script = Script.find(params[:id])
    @event  = Event.find(session[:event_id])
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def edit
    @script = Script.find(params[:id])
    @event  = Event.find(session[:event_id])
  end

  def update
    @script = Script.find(params[:id])
    @event  = Event.find(session[:event_id])

    respond_to do |format|
      if @script.update!(script_params)
        @script.run_script_at unless @script.run_start_at.nil?
        format.html { redirect_to(@script, :notice => 'Record was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.xml
  def destroy
    @script = Script.find(params[:id])
    @script.destroy

    respond_to do |format|
      format.html { redirect_to(scripts_url) }
      format.xml  { head :ok }
    end
  end


  private

  def script_params
    params.require(:script).permit(:event_id, :script_type_id, :button_label, :file_name, :published, :run_start_at, :run_till, :run_at_intervals)
  end

end