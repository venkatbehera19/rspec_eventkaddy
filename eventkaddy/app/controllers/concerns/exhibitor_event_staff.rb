module ExhibitorEventStaff
  extend ActiveSupport::Concern

  def create_event_roles_and_attendee(user, exhibitor, es_params)

    exhibitor_role_id = Role.find_by_name('Exhibitor')&.id
    attendee_role_id  = Role.find_by_name('Attendee')&.id

    return false unless exhibitor_role_id && attendee_role_id

    UsersRole
      .find_or_create_by(
        role_id: exhibitor_role_id,
        user_id: user.id
      )

    users_event       = UsersEvent.find_or_create_by(
                          user_id: user.id,
                          event_id: exhibitor.event_id
                        )

    UserEventRole
      .find_or_create_by(
        role_id: exhibitor_role_id,
        users_event_id: users_event.id
      )

    if es_params[:is_attendee]
      attendee_type     = AttendeeType.where(name: 'Exhibitor').first
      attendee_params   = es_params.except(:is_attendee)
                          .merge(
                            company: exhibitor.company_name,
                            attendee_type_id: attendee_type.id,
                            badge_name: user.first_name,
                            custom_filter_1: 'EXHIBITOR'
                            )
      attendee = Attendee.create!(attendee_params)
      attendee.qr_image
      if attendee.present?
        UsersRole
          .find_or_create_by(
            role_id: attendee_role_id,
            user_id: @user.id
          )
        UserEventRole
          .find_or_create_by(
            role_id: attendee_role_id,
            users_event_id: users_event.id
          )
      end
    end
    true
  end

  def handle_exhibitor_staff(user, exhibitor, exhibitor_staff_params, es_params)

    @exhibitor_staff = ExhibitorStaff.find_by( event_id: exhibitor.id, user_id: user.id)

    if !@exhibitor_staff.present? && es_params[:email] == current_user.email
      ex_st_params     = exhibitor_staff_params.except(:password)
                          .merge(event_id: exhibitor.event_id, user_id: user.id, is_exhibitor: true)
      @exhibitor_staff = exhibitor.exhibitor_staffs.create!(ex_st_params)
    elsif !@exhibitor_staff.present?
      ex_st_params     = exhibitor_staff_params.except(:password)
                          .merge(event_id: exhibitor.event_id, user_id: user.id, is_exhibitor: false)
      @exhibitor_staff = exhibitor.exhibitor_staffs.create!(ex_st_params)
    else
      staff_update_params = exhibitor_staff_params.except(:is_attendee)
      @exhibitor_staff.update(staff_update_params)
    end
    @exhibitor_staff
  end
end
