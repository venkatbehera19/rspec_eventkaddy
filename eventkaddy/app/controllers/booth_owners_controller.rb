class BoothOwnersController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  def multiple_new
    exhibitor_companies = Exhibitor.where(event_id:session[:event_id]).where.not(company_name: nil).pluck(:company_name)
    # hack for avma's booth names in the company names
    exhibitor_companies.map! {|c| c.include?('Booth') ? c.split(' ')[0..-4].join(' ') : c }

    @attendees = Attendee.
      select('id, company, first_name, last_name, business_unit').
      where(event_id:session[:event_id], company:exhibitor_companies).
      order(:company)

    @selected = BoothOwner.where(attendee_id:@attendees.map(&:id)).pluck(:attendee_id)
  end

  def update_multiple_new
    exhibitor_type_id = AttendeeType.where(name:'Exhibitor').first.id
    names = []
    params[:attendee_ids] ||= []
    Attendee.select('id, first_name, last_name, company, account_code, username')
            .where(id:params[:attendee_ids])
            .each {|attendee|
              exhibitors = Exhibitor.where(event_id:session[:event_id], company_name:attendee.company)
              exhibitor_id = if exhibitors.length > 0
                               exhibitors.first.id
                             else
                               Exhibitor.where(event_id:session[:event_id]).where('company_name LIKE ?', '%' + attendee.company + ' - Booth%').first.id
                             end
              BoothOwner.where(attendee_id:attendee.id,exhibitor_id:exhibitor_id).first_or_create
              #attendee.update! attendee_type_id: exhibitor_type_id
              names << attendee.full_name
            }

    # only delete attendees with matching company names, since those are the only
    # ones that can appear in the select list; booth_owners made through other means
    # should not appear or be deleted by these methods

    exhibitor_companies = Exhibitor.where(event_id:session[:event_id]).where.not(company_name: nil).pluck(:company_name)
    # hack for avma's booth names in the company names
    exhibitor_companies.map! {|c| c.include?('Booth') ? c.split(' ')[0..-4].join(' ') : c }

    attendees_ids_available_to_delete = Attendee.
      where(event_id:session[:event_id], company:exhibitor_companies).
      pluck(:id)

    booth_owners_attendee_ids = BoothOwner.
      where(attendee_id:attendees_ids_available_to_delete).
      pluck(:attendee_id)

    ids_to_delete = booth_owners_attendee_ids - params[:attendee_ids].map(&:to_i)

    BoothOwner.where(attendee_id:ids_to_delete).delete_all

    Attendee.cleanup_abandoned_booth_owners session[:event_id]

    respond_to do |format|
      format.html { redirect_to "/booth_owners/multiple_new", :notice => 'Successfully updated Booth Owners.' }
    end
  end

  def exhibitor_booth_owner
    @exhibitor = Exhibitor.find_by(event_id: session[:event_id], id: params[:exhibitor_id])

    @selected = Attendee.joins(:booth_owners).where(booth_owners: {exhibitor_id: @exhibitor.id})

    @attendees = Attendee.where(event_id:session[:event_id]).order(:company)
  end

  def add_booth_owner_for_exhibitor
    attendee = Attendee.find_by(id: params[:attendee_id])
    exhibitor = Exhibitor.find_by(id: params[:exhibitor_id])
    message = nil
    if exhibitor && attendee
      if params[:type] == 'remove'
        booth_owner = BoothOwner.find_by(attendee: attendee, exhibitor: exhibitor).destroy
        message = 'Removed'
      elsif params[:type] == 'add'
        booth_owner = BoothOwner.create(attendee: attendee, exhibitor: exhibitor)
        message = 'Added' 
      end 
    end

    render json: {status: 200, message: message}
  end

  private

  # def booth_owner_params
  #   params.require(:booth_owner).permit(:exhibitor_id, :attendee_id)
  # end

end