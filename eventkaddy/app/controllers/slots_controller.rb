class SlotsController < ApplicationController
  before_action :set_slot, only: [:show, :edit, :update, :destroy, :cancel]
  include ExhibitorPortalsHelper
  layout :set_layout

  # GET /slots
  def index
    @is_exhibitor         = !current_user.is_a_staff?
    @exhibitor            = get_exhibitor
    @exhibitor && check_for_payment
    @event                = Event.find session[:event_id]
    if @is_exhibitor
      # Provide slot booking feature if there is no staff
      @exhibitor_staff    = ExhibitorStaff.where(exhibitor_id: @exhibitor.id, event_id:session[:event_id], is_exhibitor:true, user_id: current_user.id).first_or_create
      staffs              = @exhibitor.exhibitor_staffs.where(is_exhibitor:false)
      #@has_no_staffs      = staffs.blank?
    else
      @exhibitor_staff    = ExhibitorStaff.find_by(user_id: current_user.id, event_id: session[:event_id])
    end
    if !@is_exhibitor || @exhibitor.enable_exhibitor_time_slots
      all_slots           = Slot.where(event_id: session[:event_id], exhibitor_staff_id: @exhibitor_staff.id).order(:start_time)
      @slots              = all_slots.to_a.filter{|s| s.start_time > (Time.now + 15.minutes)}
      @date_slots         = arrange_dateslots(@slots)
      @booked_slots       = @slots.to_a.filter{|s| !!s.attendee_id }
      @booked_date_slots    = arrange_dateslots(@booked_slots)
    end
    type_id               = SettingType.where(name:'exhibitor_timeslots').first.id
    @setting              = Setting.where(event_id:session[:event_id], setting_type_id:type_id).first_or_initialize
  end

  # GET /slots/1
  def show
    @event                = Event.find session[:event_id]
  end

  # GET /slots/new
  def new
    form_init
    @slot                 = Slot.new(event_id: session[:event_id], exhibitor_staff_id: @exhibitor_staff.id, slot_duration: @setting.duration)
  end

  # GET /slots/1/edit
  def edit
    @event                = Event.find session[:event_id]
    form_init
    @slot.slot_duration   = @setting.duration
  end

  # POST /slots
  def create
    # Work on validation of overlapping slots
    @event = Event.find session[:event_id]
    errors = []
    slot_params[:start_time].each do |start_time|
      all_params = slot_params
      all_params[:start_time] = (slot_params[:slot_day] + " " + start_time).to_datetime.change(:offset => @event.utc_offset)
      all_params[:end_time] = (all_params[:start_time] + slot_params[:slot_duration].to_i.minutes)
      slot = Slot.where(event: session[:event_id], exhibitor_staff_id: all_params[:exhibitor_staff_id], start_time: all_params[:start_time]).first_or_initialize
      slot.assign_attributes(all_params.merge({stage: 1}))
      slot.save
      if slot.errors
        errors <<  "#{start_time}: #{slot.errors.full_messages}"
      end
    end
    respond_to do |format|
      format.html { redirect_to slots_path :notice => (errors.blank? ? 'Slot(s) created successfully.' : errors.flatten) }
    end
  end

  # PATCH/PUT /slots/1
  def update
    @event = Event.find session[:event_id]
    all_params = slot_params
    all_params[:start_time] = (slot_params[:slot_day] + " " + slot_params[:start_time]).to_datetime.change(:offset => @event.utc_offset)
    all_params[:end_time] = (all_params[:start_time] + slot_params[:slot_duration].to_i.minutes)
    @another_slot = Slot.where(event: session[:event_id], exhibitor_staff_id: @slot.exhibitor_staff_id, start_time: all_params[:start_time]).limit(1)
    if !@another_slot.blank? &&  @another_slot.first.id != @slot.id
      redirect_to edit_slot_path(@slot), alert: 'A timeslot is already present with the given date and time.'
      return
    end

    if @slot.update(all_params)
      redirect_to @slot, notice: 'Slot was successfully updated.'
    else
      render :edit, alert: @slot.errors.to_sentence
    end
  end

  def cancel
    @event           = Event.find session[:event_id]
    attendee_id      = @slot.attendee_id
    if @slot.update_column(:attendee_id, nil)
      exhibitor_staff = ExhibitorStaff.find(@slot.exhibitor_staff_id)
      attendee        = Attendee.find(attendee_id)
      CalendarInviteMailer.cancel(@event, attendee, @slot, exhibitor_staff.full_name).deliver_later
      CalendarInviteMailer.cancel(@event, exhibitor_staff, @slot, attendee.full_name).deliver_later
      redirect_to @slot, notice: "Meeting slot was successfully cancelled."
    else
      redirect_to @slot, alert: "Could not cancel this meeting at this moment."
    end

  end

  # DELETE /slots/1
  def destroy
    @slot.destroy
    redirect_to slots_url, notice: 'Slot was successfully destroyed.'
  end

  def update_exhibitor_time_slot_status
    @is_exhibitor         = !current_user.is_a_staff?
    if !@is_exhibitor
      flash[:alert] = "You are not authorized for this action"
      render json: { alert: "unauth_access" }
    else
      status = params[:checked_status].eql?('true')
      exhibitor = get_exhibitor
      exhibitor.update! enable_exhibitor_time_slots: status
      flash[:notice] = "Exhibitor time slots #{status ? 'enabled' : 'disabled'}"
      render json: { status: 'ok' }, status: 200
    end
  end

  private

    def get_exhibitor
      if current_user.role? :exhibitor then
        if current_user.is_a_staff?
          es = ExhibitorStaff.find_by(user_id: current_user.id, event_id: session[:event_id])
          return Exhibitor.find es.exhibitor_id
        else
          current_user.first_or_create_exhibitor( session[:event_id] )
        end
      elsif !session[:exhibitor_id_portal].blank?
        puts "test: #{session[:exhibitor_id_portal]}"
        Exhibitor.find(session[:exhibitor_id_portal])
      end
    end

    def set_layout
      if current_user.role? :exhibitor then
        'exhibitorportal'
      else
        'subevent_2013'
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_slot
      @slot = Slot.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def slot_params
      params.fetch(:slot, {}).permit(:event_id, :exhibitor_staff_id, :organizer, :slot_day, :meeting_description, :slot_duration, :start_time, start_time: [])
    end

    # Create a key value pair for dates and slots
    def arrange_dateslots slots
      dateslots = {}
      slots.each do |slot|
        slot_time = slot.start_time.localtime(@event.utc_offset)
        if dateslots[slot_time.to_date] == nil
          dateslots[slot_time.to_date] = []
        end
        dateslots[slot_time.to_date] << slot
      end
      return dateslots
    end

    def form_init
      type_id               = SettingType.where(name:'exhibitor_timeslots').first.id
      @setting              = Setting.where(event_id:session[:event_id], setting_type_id:type_id).first_or_initialize
      @exhibitor_staff      = ExhibitorStaff.find_by(user_id: current_user.id, event_id: session[:event_id])
      days_range            = @setting.date_range.split(' - ')
      start_day             = Date.strptime(days_range[0], '%m/%d/%Y')
      start_day             = start_day < Time.now.to_date ? Time.now.to_date : start_day
      end_day               = Date.strptime(days_range[1], '%m/%d/%Y')
      @date_range           = []
      while( start_day <= end_day) do
        @date_range  << start_day.strftime("%A, %B %d %Y").to_s
        start_day += 1.day
      end
      @time_range           = []
      start_time = Time.strptime(@setting.start_time, "%I:%M %p")
      end_time = Time.strptime(@setting.end_time, "%I:%M %p")
      while( start_time <= end_time) do
        @time_range  << start_time.strftime("%I:%M %p").to_s
        start_time +=  @setting.duration.to_i.minutes
      end
    end
end
