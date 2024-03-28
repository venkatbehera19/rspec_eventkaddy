class ScriptTypesController < ApplicationController

  load_and_authorize_resource
  layout 'subevent_2013'
  
  def index
    @script_types = ScriptType.all
    @event  = Event.find(session[:event_id])
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def show
    @script_type = ScriptType.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @script_type = ScriptType.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @script_type = ScriptType.find(params[:id])
  end

  def create
    @script_type = ScriptType.new(script_type_params)

    respond_to do |format|
      if @script_type.save
        format.html { redirect_to(@script_type, :notice => 'Record was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def new_button_from_script_type
    @script_type = ScriptType.find(params[:id])
    event = Event.find(session[:event_id])
    @new_script = Script.where(event_id:event.id,button_label:@script_type.name, script_type_id:@script_type.id, published:false, file_name:@script_type.file_name).first_or_create
    respond_to do |format|
      format.html { redirect_to(script_types_path, :notice => "script added to #{event.name}.") }
    end
  end

  def update
    @script_type = ScriptType.find(params[:id])

    respond_to do |format|
      if @script_type.update!(script_type_params)
        format.html { redirect_to(@script_type, :notice => 'Integration record was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.xml
  def destroy
    @script_type = ScriptType.find(params[:id])
    @script_type.destroy

    respond_to do |format|
      format.html { redirect_to(script_types_path) }
      format.xml  { head :ok }
    end
  end

  private

  def script_type_params
    params.require(:script_type).permit(:name, :url, :post_request, :job, :file_name)
  end

end