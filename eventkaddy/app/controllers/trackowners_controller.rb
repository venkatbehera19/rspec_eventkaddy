class TrackownersController < ApplicationController
  layout 'subevent_2013'

  load_and_authorize_resource


  def index

    @trackowners = Trackowner.where(event_id:session[:event_id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @trackowners }
    end

  end


  def show
    @trackowner = Trackowner.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trackowner }
      format.json { render :json => @trackowner.to_json, :callback => params[:callback] }
    end
  end


  def new
    @trackowner = Trackowner.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trackowner }
    end
  end


  def edit
    @trackowner = Trackowner.find(params[:id])

  end


  def create
    @trackowner = Trackowner.new(trackowner_params)
    @trackowner.updatePhoto(params)


    respond_to do |format|
      if @trackowner.save
        User.first_or_create_for_trackowner @trackowner, params[:password]
        format.html { redirect_to(@trackowner, :notice => 'Trackowner was successfully created.') }
        format.xml  { render :xml => @trackowner, :status => :created, :location => @trackowner }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @trackowner.errors, :status => :unprocessable_entity }
      end
    end
  end


  def update
    @trackowner = Trackowner.find(params[:id])
    @trackowner.updatePhoto(params)

    respond_to do |format|
      if @trackowner.update!(trackowner_params)
        User.first_or_create_for_trackowner @trackowner, params[:password]

        format.html { redirect_to(@trackowner, :notice => 'Trackowner was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @trackowner.errors, :status => :unprocessable_entity }
      end
    end
  end


  def destroy
    @trackowner = Trackowner.find(params[:id])
    @trackowner.destroy

    respond_to do |format|
      format.html { redirect_to('/trackowners') }
      format.xml  { head :ok }
    end
  end

  private

  def trackowner_params
    params.require(:trackowner).permit(:email, :event_id, :first_name, :honor_prefix, :honor_suffix, :last_name, :photo_event_file_id, :token, :unsubscribed, :user_id)
  end

end