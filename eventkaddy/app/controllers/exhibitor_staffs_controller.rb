class ExhibitorStaffsController < ApplicationController
  include ExhibitorStaffsHelper
  include ExhibitorPortalsHelper
  include ExhibitorEventStaff

  layout :set_layout

  helper_method :is_booth_owner?
  def index
    @user_is_exhibitor    = !current_user.is_a_staff?
    @exhibitor            = get_exhibitor
    @exhibitor && check_for_payment
    @event                = Event.find session[:event_id]
    if @user_is_exhibitor
      @exhibitor_staff    = ExhibitorStaff.where(exhibitor_id: @exhibitor.id, event_id:session[:event_id], is_exhibitor:true).first_or_create
    else
      @exhibitor_staff    = ExhibitorStaff.find_by_user_id current_user.id
    end
    # I assumed there will be only 1 exhibitor for each event
    # Otherwise use; @exhibitor_staffs     = ExhibitorStaff.where(event_id:session[:event_id],is_exhibitor:false)
    @exhibitor_staffs     = @exhibitor.exhibitor_staffs
    type_id               = SettingType.where(name:'exhibitor_portal_settings').first.id
    s                     = Setting.where(event_id: @event.id, setting_type_id:type_id).first

    if current_user.orders
      staff_member_purchased_items = current_user.orders.where(status: "paid").map{|a| a.order_items.select{|a| a.item_type == 'Product' && a.item.product_category.iid == 'staff_members'}}
      @staff_members_limit_purchased = staff_member_purchased_items.flatten.reduce(0){|sum, item| sum = sum + item.quantity; sum}
      lead_retrieval_purchased_items = current_user.orders.where(status: "paid").map{|a| a.order_items.select{|a| a.item_type == 'Product' && a.item.product_category.iid == 'lead_retrieval'}}
      @lead_retrieval_limit_purchased = lead_retrieval_purchased_items.flatten.reduce(0){|sum, item| sum = sum + item.quantity; sum}
    end
    @exhibitor = current_user.exhibitors.where(event_id: @event.id ).first
    if @exhibitor && @exhibitor.staffs
      @discounted_passes = @exhibitor.staffs["discount_staff_count"].to_s
      @complimentary_passes = @exhibitor.staffs["complimentary_staff_count"].to_s
      @lead_retrieval_passes = @exhibitor.staffs["lead_retrieval_count"].nil? ? "0": @exhibitor.staffs["lead_retrieval_count"].to_s
    end
    if s && s.limit_no_of_staffs
      @staff_members_limit  = @staff_members_limit_purchased.to_i + s.limit_no_of_staffs.to_i + @complimentary_passes.to_i
    else
      @staff_members_limit  = @staff_members_limit_purchased.to_i + @complimentary_passes.to_i
      @lead_retrieval_limit_purchased = @lead_retrieval_limit_purchased + @lead_retrieval_passes.to_i
    end
    @staff_members_count  = @exhibitor_staffs.count
    attendee_type_id = AttendeeType.find_by(name: 'Exhibitor Lead Retrieval').id
    @lead_retreval_attendees = Attendee.where(email: @exhibitor_staffs.map(&:email), event_id: session[:event_id], attendee_type_id: attendee_type_id).group_by(&:email)
    @current_tab = get_current_tab("Staff Members")
    @current_user_attendee = Attendee.where(email: current_user.email, event_id: session[:event_id]).first
  end

  def staffs
    exhibitor_id = params[:id]
    @exhibitor   = Exhibitor.find exhibitor_id
    user         = @exhibitor.user
    if user
      @user_is_exhibitor    = !user.is_a_staff?
    end
    @exhibitor_staffs     = @exhibitor.exhibitor_staffs
    s                     = get_settings
    if user&.orders
      orders = user.orders
                    .where(status: 'paid')
                    .includes(:order_items, [transaction_detail: :mode_of_payment])
                    .where(mode_of_payment: {event_id: session[:event_id]})
      staff_member_purchased_items    = orders.map{|a| a.order_items.select{|a| a.item_type == 'Product' && a.item.product_category.iid == 'staff_members'}}
      @staff_members_limit_purchased  = staff_member_purchased_items.flatten.reduce(0){|sum, item| sum = sum + item.quantity; sum}
      lead_retrieval_purchased_items  = orders.map{|a| a.order_items.select{|a| a.item_type == 'Product' && a.item.product_category.iid == 'lead_retrieval'}}
      @lead_retrieval_limit_purchased = lead_retrieval_purchased_items.flatten.reduce(0){|sum, item| sum = sum + item.quantity; sum}
    end
    if @exhibitor.present? && @exhibitor.staffs.present?
      @discounted_passes = @exhibitor.staffs["discount_staff_count"].to_s
      @complimentary_passes = @exhibitor.staffs["complimentary_staff_count"].to_s
    end
    if s && s.limit_no_of_staffs
      @staff_members_limit  = @staff_members_limit_purchased.to_i + s.limit_no_of_staffs.to_i + @complimentary_passes.to_i
    else
      @staff_members_limit  = @staff_members_limit_purchased.to_i + @complimentary_passes.to_i
    end
    @staff_members_count     = @exhibitor_staffs.count
    attendee_type_id         = AttendeeType.find_by(name: 'Exhibitor Lead Retrieval').id
    @lead_retreval_attendees = Attendee
                                .where(
                                  email: @exhibitor_staffs.map(&:email),
                                  event_id: session[:event_id],
                                  attendee_type_id: attendee_type_id
                                ).group_by(&:email)
  end

  def show
    redirect_to '/exhibitor_portals/staff_members'
  end

  def new
    @exhibitor        = get_exhibitor
    @settings         = get_settings
    @exhibitor_staff  = @exhibitor.exhibitor_staffs.new
  end

  def new_staff
    @exhibitor        = Exhibitor.find params[:id]
    @settings         = get_settings
    @exhibitor_staff  = @exhibitor.exhibitor_staffs.new
  end

  def create
    @exhibitor        = Exhibitor.find(params[:exhibitor_id])
    @exhibitor_staff  = @exhibitor.exhibitor_staffs.new
    @user             = User.find_by_email(exhibitor_staff_params[:email]) || User.new(exhibitor_staff_params.slice(:email,:password))

    current_user_email_domain = current_user.email.split('@')[1]
    added_user_email_domain   = @user.email.split('@')[1]

    settings         = get_settings
    if settings.check_email_domain
      if current_user_email_domain != added_user_email_domain
        respond_to do |format|
          format.html { redirect_to(exhibitor_portals_staff_members_path, :alert => 'Email Domain does not match with exhibitors email.') }
          format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :unprocessable_entity }
        end
      else
        if @user.id
          if !ExhibitorStaff.where(event_id: @exhibitor.event_id, user_id: @user.id).blank?
            redirect_back fallback_location: root_url, alert: "User with email #{exhibitor_staff_params[:email]} is already a staff of other exhibitor"
          else
            es_params   = exhibitor_staff_params
                            .except(:password)
                            .merge(event_id: @exhibitor.event_id, user_id: @user.id)

            exhibitor_staff = handle_exhibitor_staff(@user, @exhibitor, exhibitor_staff_params, es_params)
            if exhibitor_staff.present?
              if create_event_roles_and_attendee(@user, @exhibitor, es_params)
                respond_to do |format|
                  format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff Attendee was successfully created.') }
                  format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :created }
                end
              end
            end
          end
        else
          if @user.save
            es_params   = exhibitor_staff_params
                            .except(:password)
                            .merge(event_id: @exhibitor.event_id, user_id: @user.id)
            exhibitor_staff = handle_exhibitor_staff(@user, @exhibitor, exhibitor_staff_params, es_params)
            if exhibitor_staff.present?
              if create_event_roles_and_attendee(@user, @exhibitor, es_params)
                respond_to do |format|
                  format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff was successfully created.') }
                  format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :created }
                end
              end
            end
          else
            @user.destroy
            respond_to do |format|
              format.html { render :action => "new", :exhibitor_id => @exhibitor.id }
              format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
            end
          end
        end
      end
    else
      if @user.id
        if !ExhibitorStaff.where(event_id: @exhibitor.event_id, user_id: @user.id).blank?
          redirect_back fallback_location: root_url, alert: "User with email #{exhibitor_staff_params[:email]} is already a staff of other exhibitor"
        else
          es_params   = exhibitor_staff_params
                          .except(:password)
                          .merge(event_id: @exhibitor.event_id, user_id: @user.id)
          exhibitor_staff = handle_exhibitor_staff(@user, @exhibitor, exhibitor_staff_params, es_params)
          if exhibitor_staff.present?
            if create_event_roles_and_attendee(@user, @exhibitor, es_params)
              respond_to do |format|
                format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff Attendee was successfully created.') }
                format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :created }
              end
            end
          end
        end
      else
        if @user.save
          es_params        = exhibitor_staff_params.except(:password).merge(event_id: @exhibitor.event_id, user_id: @user.id)
          @exhibitor_staff  = @exhibitor.exhibitor_staffs.create!(es_params)
          if @exhibitor_staff
            if create_event_roles_and_attendee(@user, @exhibitor, es_params)
              respond_to do |format|
                format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff was successfully created.') }
                format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :created }
              end
            end
          end
        else
          @user.destroy
          respond_to do |format|
            format.html { render :action => "new", :exhibitor_id => @exhibitor.id }
            format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
  end

  def create_staff
    @exhibitor        = Exhibitor.find(params[:exhibitor_id])
    @exhibitor_staff  = @exhibitor.exhibitor_staffs.new
    @user             = User.find_by_email(exhibitor_staff_params[:email]) || User.new(exhibitor_staff_params.slice(:email,:password))

    if @user.id

      if !ExhibitorStaff.where(event_id: @exhibitor.event_id, user_id: @user.id).blank?
        redirect_back fallback_location: root_url, alert: "User with email #{exhibitor_staff_params[:email]} is already a staff of other exhibitor"
      else
        users_event = UsersEvent.find_or_create_by!(
                          user_id: @user.id,
                          event_id: @exhibitor.event_id
                        )
        es_params   = exhibitor_staff_params
                        .except(:password)
                        .merge(event_id: @exhibitor.event_id, user_id: @user.id)
        if @user.role?('TrackOwner')
          user_role = UsersRole.find_or_create_by(
                          role_id: Role.find_by_name('Exhibitor').id,
                          user_id: @user.id
                        )
          exhibitor_staff = ExhibitorStaff
                            .where(
                              event_id: @exhibitor.event_id,
                              user_id: @user.id
                            ).first
          if !exhibitor_staff.present?
            ex_st_params = exhibitor_staff_params.except(:password).merge(event_id: @exhibitor.event_id, user_id: @user.id, is_exhibitor: false)
            @exhibitor_staff  = @exhibitor.exhibitor_staffs.create!(ex_st_params)

            UserEventRole
              .find_or_create_by(
                role_id: Role.find_by_name('Exhibitor').id,
                users_event_id: users_event.id
              )

            if !es_params[:is_attendee].nil?
              attendee_type   = AttendeeType.where(name: 'Exhibitor').first
              attendee_params = es_params.except(:is_attendee).merge(company: @exhibitor.company_name, attendee_type_id: attendee_type.id, custom_filter_1: 'Exhibitor', badge_name: @user.first_name)
              attendee        = Attendee.find_or_create_by(attendee_params)
              attendee.qr_image

              UsersRole
              .find_or_create_by(
                role_id: Role.find_by_name('Attendee').id,
                user_id: @user.id
              )
              UserEventRole
                .find_or_create_by(
                  role_id: Role.find_by_name('Attendee').id,
                  users_event_id: users_event.id
                )
            end
            #
          end
        else
          user_role = UsersRole
                        .find_or_create_by(
                          role_id: Role.find_by_name('Exhibitor').id,
                          user_id: @user.id
                        )
          exhibitor_staff = ExhibitorStaff
                            .where(
                              event_id: @exhibitor.event_id,
                              user_id: @user.id
                            ).first
          if !exhibitor_staff.present?
            ex_st_params = exhibitor_staff_params.except(:password).merge(event_id: @exhibitor.event_id, user_id: @user.id, is_exhibitor: false)
            @exhibitor_staff  = @exhibitor.exhibitor_staffs.create!(ex_st_params)
          else
            staff_update_params = exhibitor_staff_params.except(:is_attendee)
            exhibitor_staff.update(staff_update_params)
          end

          UserEventRole
          .find_or_create_by(
            role_id: Role.find_by_name('Exhibitor').id,
            users_event_id: users_event.id
          )
          if !es_params[:is_attendee].nil?
            attendee_type   = AttendeeType.where(name: 'Exhibitor').first
            attendee_params = es_params.except(:is_attendee).merge(company: @exhibitor.company_name, attendee_type_id: attendee_type.id, custom_filter_1: 'Exhibitor', badge_name: @user.first_name)
            attendee        = Attendee.find_or_create_by(attendee_params)
            attendee.qr_image
            UsersRole
              .find_or_create_by(
                role_id: Role.find_by_name('Attendee').id,
                user_id: @user.id
              )
            UserEventRole
              .find_or_create_by(
                role_id: Role.find_by_name('Attendee').id,
                users_event_id: users_event.id
              )
          end
        end
        respond_to do |format|
          format.html { redirect_to("/exhibitor_staffs/staffs/#{@exhibitor.id}", :notice => 'Staff Attendee was successfully created.') }
          format.xml  { render :xml => "/exhibitor_staffs/staffs/#{@exhibitor.id}", :status => :created }
        end
      end
    else
      if @user.save
        es_params        = exhibitor_staff_params.except(:password).merge(event_id: @exhibitor.event_id, user_id: @user.id)
        @exhibitor_staff  = @exhibitor.exhibitor_staffs.create!(es_params)
        if @exhibitor_staff
          UsersRole.create(role_id: Role.find_by_name('Exhibitor').id, user_id: @user.id)
          users_event = UsersEvent.create(user_id: @user.id, event_id: @exhibitor.event_id)
          UserEventRole
          .find_or_create_by(
            role_id: Role.find_by_name('Exhibitor').id,
            users_event_id: users_event.id
          )
          if !es_params[:is_attendee].nil?
            # adding the exhibitor as an attendee
            # adding the role as a attendee aswell
            attendee_type   = AttendeeType.where(name: 'Exhibitor').first
            attendee_params = es_params.except(:is_attendee).merge(company: @exhibitor.company_name, attendee_type_id: attendee_type.id, custom_filter_1: 'Exhibitor', badge_name: @user.first_name)
            attendee = Attendee.create!(attendee_params)
            attendee.qr_image
            UsersRole
            .create(
              role_id: Role.find_by_name('Attendee').id,
              user_id: @user.id
            )
            UserEventRole
            .find_or_create_by(
              role_id: Role.find_by_name('Attendee').id,
              users_event_id: users_event.id
            )
          end

          respond_to do |format|
            format.html { redirect_to("/exhibitor_staffs/staffs/#{@exhibitor.id}", :notice => 'Staff was successfully created.') }
            format.xml  { render :xml => "/exhibitor_staffs/staffs/#{@exhibitor.id}", :status => :created }
          end
        end
      else
        @user.destroy
        respond_to do |format|
          format.html { render :action => "new_staff", :exhibitor_id => @exhibitor.id }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    end

  end

  def check_existing_email
    @email_exists = !User.where(email: params[:email]).blank?
    render json: {email_exists: @email_exists}
  end

  def edit
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
  end

  def update
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    updated          = @exhibitor_staff.update!(staff_update_params)
    @exhibitor_staff.update_photo(params[:photo_file]) if params[:photo_file]

    if updated
      if !params[:exhibitor_staff][:email].blank?
        user = User.find @exhibitor_staff.user_id
        user.update!(email: params[:exhibitor_staff][:email])
      end
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff was successfully updated.') }
        format.xml  { render :xml => exhibitor_portals_staff_members_path, :status => :updated }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exhibitor_staff.errors, :status => :unprocessable_entity }
      end
    end
  end

  def associate_attendee_account
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    exhibitor_type_id = AttendeeType.where(name:'Exhibitor').first.id

    booth = BoothOwner.find_by_exhibitor_staff_id(@exhibitor_staff.id)
    !booth.blank? && (redirect_to(exhibitor_portals_staff_members_path, :notice => 'Staff is already a booth owner.') and return)
    # exhibitor_staff_attendee = Attendee.where(event_id:session[:event_id]).where('first_name=? AND last_name=? AND company LIKE ?',@exhibitor_staff.first_name, @exhibitor_staff.last_name, '%' + @exhibitor_staff.exhibitor.company_name + '%').first
    exhibitor_staff_attendee = Attendee.where(
      event_id: session[:event_id],
      email: @exhibitor_staff.email,
      company: @exhibitor_staff.exhibitor.company_name
    )
    if exhibitor_staff_attendee.blank?
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :alert => 'No attendee profile found associated to this staff. Please contact support@eventkaddy.com to get one.') }
        format.xml  { render :xml => "<script>alert('Associated attendee account not found. Please contact support@eventkaddy.com.')</script>".html_safe, :status => :unprocessable_entity }
      end
    else
      BoothOwner.where(
        attendee_id: exhibitor_staff_attendee.first.id,
        exhibitor_id: @exhibitor_staff.exhibitor_id,
        exhibitor_staff_id: @exhibitor_staff.id
      ).first_or_create
      exhibitor_staff_attendee.first.update! attendee_type_id: exhibitor_type_id
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Booth owner added successfully!') }
        format.xml  { render :xml => "<script>alert('Booth owner added successfully!')</script>".html_safe, :status => :created }
      end
    end
  end

  def remove_booth_owner
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    booth = BoothOwner.find_by_exhibitor_staff_id(@exhibitor_staff.id)
    if booth.blank?
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :alert => 'No Booth owner associated to this staff.') }
      end
    else
      booth.destroy
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Booth owner removed successfully!') }
      end
    end
  end

  def destroy
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    @attendee        = Attendee.where(email: @exhibitor_staff.email, event_id: @exhibitor_staff.event_id).first
    users_event      = UsersEvent.find_or_create_by( user_id: @exhibitor_staff.user_id, event_id: @exhibitor_staff.event_id )
    attendee_role_id = Role.find_by_name('Attendee')&.id
    user_event_role  = UserEventRole.where(users_event_id: users_event.id, role_id: attendee_role_id).first

    user_event_role&.delete
    @attendee&.delete

    if !@exhibitor_staff.vchat_room.blank?
      delete_room(@exhibitor_staff.room_name)
    end
    @exhibitor_staff.destroy

    respond_to do |format|
      format.html { redirect_to exhibitor_portals_staff_members_path,  :notice => 'Staff was successfully deletd.'}
      format.json { head :ok }
    end
  end

  def create_vchat_room
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    @exhibitor_staff.vchat_room = create_room(@exhibitor_staff)
    if @exhibitor_staff.vchat_room
      @exhibitor_staff.save!
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Video Chat Room successfully deleted.') }
      end
    else
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Something went wrong.') }
      end
    end
  end

  def delete_vchat_room
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    delete_room(@exhibitor_staff.room_name)
    @exhibitor_staff.vchat_room = nil
    if @exhibitor_staff.save
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Video Chat Room successfully deleted.') }
      end
    else
      respond_to do |format|
        format.html { redirect_to(exhibitor_portals_staff_members_path, :notice => 'Something went wrong.') }
      end
    end
  end

  def enable_lead_retrieval
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    attendee = Attendee.find_by(email: @exhibitor_staff.email, event_id: @exhibitor_staff.event_id)
    attendee_type_id = AttendeeType.find_by(name: 'Exhibitor Lead Retrieval').id
    if attendee.present?
      if attendee.attendee_type_id != attendee_type_id
        attendee.update_columns(attendee_type_id: attendee_type_id);
      end
    else
      attendee = Attendee.new(
        event_id: @exhibitor_staff.event_id,
        first_name: @exhibitor_staff.first_name,
        last_name: @exhibitor_staff.last_name,
        title: @exhibitor_staff.title,
        email: @exhibitor_staff.email,
        attendee_type_id: attendee_type_id
      )
      attendee.save
      attendee.qr_image
    end
    redirect_to(exhibitor_portals_staff_members_path, :notice => 'Lead Retrieval Added.')
  end

  def delete_lead_retrieval
    @exhibitor_staff = ExhibitorStaff.find_by_slug(params[:id])
    attendee = Attendee.find_by(email: @exhibitor_staff.email, event_id: @exhibitor_staff.event_id)
    if attendee
      attendee_type     = AttendeeType.where(name: 'Exhibitor').first
      attendee.attendee_type_id = attendee_type.id
      attendee.save
    end
    redirect_to(exhibitor_portals_staff_members_path, :notice => 'Lead Retrieval Removed.')
  end

  private

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
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

  def get_settings
    type_id = SettingType.where(name:'exhibitor_portal_settings').first.id
    s       = Setting.where(event_id: session[:event_id], setting_type_id:type_id).first
    s
  end

  def is_booth_owner?(exhibitor_staff_id)
    booth = BoothOwner.find_by_exhibitor_staff_id(exhibitor_staff_id)
    !booth.blank?
  end

  def exhibitor_staff_params
    params.require(:exhibitor_staff).permit(:exhibitor_id, :last_name, :first_name, :title, :email, :password, :business_phone, :mobile_phone, :url_twitter, :url_facebook, :url_linkedin, :url_youtube, :url_instagram, :url_tiktok, :biography, :interests, :is_featured, :is_attendee)
  end

  def staff_update_params
    params.require(:exhibitor_staff).permit(:first_name, :last_name, :title, :email, :business_phone, :mobile_phone, :url_twitter, :url_facebook, :url_linkedin, :url_youtube, :url_instagram, :url_tiktok, :biography, :interests, :is_featured)
  end

  def get_current_tab(default_name)
    current_tab = Tab.tab_by_event_and_default_name session[:event_id], default_name, 'exhibitor'
  end

end
