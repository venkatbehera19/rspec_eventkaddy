class CeCertificatesController < ApplicationController
  layout :set_layout

  def index
    @event_id     = session[:event_id] 
    @certificates = CeCertificate.where(event_id: @event_id)
  end

  def create
    if CeCertificate.where(event_id: session[:event_id], name: params[:title]).exists?
      redirect_to new_ce_certificate_path, alert: 'A certificate already exists with this name.'
      return
    end
    @pdf_title        = params[:title].first.downcase.gsub(/ /, '_')
    @event_id         = session[:event_id] 
    c_type            = params[:type] ||= "default"
    system "rake prawn_pdf:all[#{@pdf_title},#{@event_id}]"
    certificate_type  = CeCertificateType.find_by_name c_type
    certificate       = CeCertificate.create( 
                          name: params[:title].first,
                          event_id: @event_id,
                          ce_certificate_type_id: certificate_type.id,
                          json: json_template.to_json,
                          mailer: mailer_template)
    !params[:certificate_background].blank? && certificate.update_photo(params[:certificate_background], "certificate_background")
    redirect_to ce_certificates_path and return
  end

  def edit
    @certificate      = CeCertificate.find params[:id] 
    @json_data        = JSON.parse @certificate.json
    @mailer_data      = JSON.parse @certificate.mailer
  end

  def update
    @certificate      = CeCertificate.find params[:id] 
    json              = update_json
    mailer            = ''
    if !params[:mailer_data].blank?
      mailer = {
        subject: params[:mailer_data][:subject],
        content: params[:mailer_data][:content]
      }
      @certificate.update!(json: json.to_json, mailer: mailer.to_json)
    else  
      @certificate.update_column(:json, json.to_json)
    end
    !params[:certificate_background].blank? && @certificate.update_photo(params[:certificate_background], "certificate_background")
    !params[:certificate_border].blank? && @certificate.update_photo(params[:certificate_border], "certificate_border")

    redirect_to ce_certificates_path and return
  end

  def destroy
    @certificate      = CeCertificate.find params[:id] 
    @pdf_title        = @certificate.name.downcase.gsub(/ /, '_')
    @event_id         = session[:event_id] 
    system "rake prawn_pdf:remove_files[#{@pdf_title},#{@event_id}]"
    @certificate.destroy

    respond_to do |format|
      format.html { redirect_to ce_certificates_path }
      format.xml  { head :ok }
    end
  end

  private
  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def json_template
    {
      display_company: false,
      display_total_hours: false,
      name_position_x: 0,
      name_position_y: 322,
      name_font_size: 25,
      name_width: 730,
      company_position_x: 0,
      company_position_y: 290,
      company_font_size: 14,
      company_width: 730,
      total_hours_position_x: 190,
      total_hours_position_y: 148,
      total_hours_font_size: 11,
      total_hours_width: 50,
      total_hours_type: 1,
      insert_table: false,
      include_suffix: false
    }
  end

  def mailer_template 
    { subject: "Your Certificate",
      content: 'Hello {{attendee}},<br><br>Thank you for attending.<br>Please find your certificate attached.<br><br><br>'
    }.to_json
  end

  def update_json
    {
      display_company: !!params[:display_company],
      display_total_hours: !!params[:display_total_hours],
      name_position_x: params[:json_data][:name_position_x].to_i,
      name_position_y: params[:json_data][:name_position_y].to_i,
      name_font_size: params[:json_data][:name_font_size].to_i,
      name_width: params[:json_data][:name_width].to_i,
      company_position_x: params[:json_data][:company_position_x].to_i,
      company_position_y: params[:json_data][:company_position_y].to_i,
      company_font_size: params[:json_data][:company_font_size].to_i,
      company_width: params[:json_data][:company_width].to_i,
      total_hours_position_x: params[:json_data][:total_hours_position_x].to_i,
      total_hours_position_y: params[:json_data][:total_hours_position_y].to_i,
      total_hours_font_size: params[:json_data][:total_hours_font_size].to_i,
      total_hours_width: params[:json_data][:total_hours_width].to_i,
      total_hours_type: params[:json_data][:total_hours_type].to_i,
      insert_table: !!params[:insert_table],
      include_suffix: !!params[:include_suffix]
    }
  end

  # private

  # def ce_certificate_params
  #   params.require(:ce_certificate).permit(:name, :event_id, :event_file_id, :ce_certificate_type_id, :json, :mailer)
  # end

end