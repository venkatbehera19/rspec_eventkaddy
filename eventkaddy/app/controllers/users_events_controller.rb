class UsersEventsController < ApplicationController
  # GET /users_events
  # GET /users_events.xml
  load_and_authorize_resource
  
  def index
    @users_events = UsersEvent.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users_events }
    end
  end

  # GET /users_events/1
  # GET /users_events/1.xml
  def show
    @users_event = UsersEvent.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @users_event }
    end
  end

  # GET /users_events/new
  # GET /users_events/new.xml
  def new
    @users_event = UsersEvent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @users_event }
    end
  end

  # GET /users_events/1/edit
  def edit
    @users_event = UsersEvent.find(params[:id])
  end

  # POST /users_events
  # POST /users_events.xml
  def create
    @users_event = UsersEvent.new(users_event_params)

    respond_to do |format|
      if @users_event.save
        format.html { redirect_to(@users_event, :notice => 'Users event was successfully created.') }
        format.xml  { render :xml => @users_event, :status => :created, :location => @users_event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @users_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users_events/1
  # PUT /users_events/1.xml
  def update
    @users_event = UsersEvent.find(params[:id])

    respond_to do |format|
      if @users_event.update!(users_event_params)
        format.html { redirect_to(@users_event, :notice => 'Users event was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @users_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users_events/1
  # DELETE /users_events/1.xml
  def destroy
    @users_event = UsersEvent.find(params[:id])
    @users_event.destroy

    respond_to do |format|
      format.html { redirect_to(users_events_url) }
      format.xml  { head :ok }
    end
  end

  private

  def users_event_params
    params.require(:users_event).permit(:user_id, :event_id)
  end

end