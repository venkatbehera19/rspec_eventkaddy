class CouponsController < ApplicationController
  layout 'subevent_2013'
  before_action :verify_as_admin_or_client
  before_action :set_event
  load_and_authorize_resource

  # GET /coupons
  # GET /coupons.xml
  def index
    @coupons = Coupon.where(event_id: @event.id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @coupons }
    end
  end

  # GET /coupons/1
  # GET /coupons/1.xml
  def show
    @coupon = Coupon.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @coupon }
    end
  end

  # GET /coupons/new
  # GET /coupons/new.xml
  def new
    @coupon = Coupon.new
	  @exhibitor_id = params[:exhibitor_id]
    @session_id = session[:event_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @coupon }
    end
  end

  # GET /coupons/1/edit
  def edit
    @coupon = Coupon.find(params[:id])
  	@exhibitor_id = @coupon.exhibitor_id
    @session_id = session[:event_id]
  end

  # POST /coupons
  # POST /coupons.xml
  def create
    @coupon = Coupon.new(coupon_params)
    @coupon.product_id = params[:product_id]
    @coupon.discount_type = params[:discount_type]

    respond_to do |format|
      if @coupon.save
        format.html { redirect_to("/coupons", :notice => 'Coupon was successfully created.') }
        format.xml  { render :xml => @coupon, :status => :created, :location => @coupon }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @coupon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /coupons/1
  # PUT /coupons/1.xml
  def update
    @coupon = Coupon.find(params[:id])

    respond_to do |format|
      if @coupon.update!(coupon_params)
        format.html { redirect_to("/coupons", :notice => 'Coupon was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @coupon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /coupons/1
  # DELETE /coupons/1.xml
  def destroy
    @coupon = Coupon.find(params[:id])
    @coupon.destroy

    respond_to do |format|
      format.html { redirect_to("/coupons") }
      format.xml  { head :ok }
    end
  end

  private
  def verify_as_admin_or_client
    raise "Your not authorized for this action" unless  (current_user.role?("Client") || current_user.role?("SuperAdmin"))
  end

  def coupon_params
    params.require(:coupon).permit(:exhibitor_id, :coupon_name, :coupon_description, :coupon_code, :coupon_link, :amount, :start_date, :end_date, :max_usage, :event_id, :product_id, :discount_type )
  end

  def set_event

    if session[:event_id].present?
      @event = Event.find_by(id: session[:event_id])
    end
    redirect_to root_url if @event.nil?
  end

end
