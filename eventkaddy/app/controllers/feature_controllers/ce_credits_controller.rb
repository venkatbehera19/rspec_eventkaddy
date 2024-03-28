
class CeCreditsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:get_certificate]

  def get_reg_id
    attendees = Attendee.where(event_id:params["event_id"],
                               first_name:params["first_name"],
                               last_name:params["last_name"])
    reg_id = attendees.first.account_code if attendees.length === 1

    if reg_id
      message = "Your Registration ID is: #{reg_id}. Click OK to return to the form (id will be automatically inserted)."
      status = "Success"
      hash = [message:message,status:status,reg_id:reg_id]

      render :json => hash.to_json
    elsif attendees.length > 1
      message = "We're sorry. There is more than one attendee with your first and last name for this event. Please contact your conference organizer to acquire your attendee id."
      status = "Failure"
      hash = [message:message,status:status]

      render :json => hash.to_json
    else
      message = "We're sorry. We could not find the given first name and last name for this event."
      status = "Failure"
      hash = [message:message,status:status]

      render :json => hash.to_json
    end

  end

  ## email CE certificate on cms for avma kiosk
  def email_ce_certificate
    @event = Event.find(48)
    @form_type = 'last_name_and_account_code_form'
    render :layout => false
  end

  def email_acvs_certificate()@event=Event.find(65);@form_type='username_only_form';render(layout:false,template:'ce_credits/email_ce_certificate');end

  def email_mte_certificate()@event=Event.find(72);@form_type='username_only_form';render(layout:false,template:'ce_credits/email_ce_certificate');end

  def generate_ce_sessions_pdf_report_cms

    case params[:event_id]
    when '48'
      redirect_url = '/email_ce_certificate'
      @form_type   = 'last_name_and_account_code_form'
    when '65'
      redirect_url = '/email_acvs_certificate'
      @form_type   = 'username_and_pass_form'
    when '72'
      redirect_url = '/email_mte_certificate'
      @form_type   = 'username_and_pass_form'
    end

    send_email              = "true"
    email                   = params[:email]
    if params[:cert_type] == "Attendance Certificate"
      type = "simple"
    else
      type = "detailed"
    end

    attendees = Attendee.where(event_id:params[:event_id], last_name:params[:last_name], account_code:params[:registration_id])

    respond_to do |format|
      if attendees.length > 0
        attendee = attendees.first
        attendee.update!(notes_email:email)
        attendee.generate_and_send_ce_sessions_pdf_report(send_email, type)
        format.html {redirect_to(redirect_url, :notice => "Successfully sent Certificate to #{email}.")}
      else
        format.html {redirect_to(redirect_url, :alert => "Could not find attendee with given last name and Registration ID. Please try again.")}
      end
    end

  end

  ## download CE certificate for AVMA bandaid

  def download_ce_certificate
    # this is actually an avma specific view, which has options for
    # the two certificates they offer. It was used in 2015 and 2016;
    # In order to preserve the 2016 version, the new one is in a 
    # different controller method, but which utilizes the same view.
    # All forms use the same action to post, as you can see 
    # in generate_ce_certificate
    @event = Event.find 158
    render :layout => false
  end

  def download_avma2017_ce_certificates
    @event = Event.find 158
    render template: "ce_credits/download_ce_certificate_userpassversion", layout: false
  end

  def download_acvs_ce_certificate
    @event = Event.find 65
    render template: "ce_credits/download_ce_certificate", layout: false
  end

  def download_mte_ce_certificate
    @event = Event.find 72
    render template: "ce_credits/download_ce_certificate", layout: false
  end

  def generate_ce_certificate
    case params[:event_name]
    when 'AVMA 2018'
      attendees = Attendee.where(event_id:158, username: params[:username], password: params[:password])
      if attendees.length > 0
        # in retrospect, remote_generate_pdf should have been passed an
        # attendee and not been responsible for finding it via account code
        params['account_code'] = attendees.first.account_code
      else
        respond_to do |format|
          format.html { 
            redirect_to(
              "/download_avma2018_ce_certificates",
              alert: "No attendee exists with that username and password for AVMA 2018."
            ) 
          }
        end
        return
      end
      params['event_id'] = 158

      if params[:cert_type] == "Detailed CE Certificate"
        remote_generate_pdf {|a| 
          Event158::GenerateDetailedCertificateOfAttendance
          .new(a).call }
      else
        remote_generate_pdf {|a| 
          Event158::GenerateCertificateOfAttendance.new(a).call}
      end
    when 'AVMA 2016'

      # necessary for remote_generate_pdf convention
      params['account_code'] = params[:registration_id]
      params['event_id']     = 78

      if params[:cert_type] == "Detailed CE Certificate"
        remote_generate_pdf {|a| 
          Event78::GenerateDetailedContinuingEducationCertificate
            .new(a).call }
      else
        remote_generate_pdf {|a| 
          Event78::GenerateCertificateOfAttendance.new(a).call}
      end
    when 'AVMA 2015'
      generate_avma_certificate params
    when 'ACVS 2015'
      generate_acvs_certificate params
    when 'MTE 2015'
      generate_mte_certificate params
    end
  end

  # this is a defunct way of doing this; we now just reference the class
  # in services/pdf_generators and invoke it with remote_generate_pdf
  def generate_avma_certificate(params)
    @total_credit_hours = 0

    def send_pdf(pdf)
        send_data pdf.render, type: "application/pdf"
    end

    def getCreditsTableDataAsArray(event_id, attendee)
      credits_array = []
      credits_array << ["Date","Session ID","Session Name","Speaker Name","Credit Hours"]

      session_codes = []
      session_codes = attendee.iattend_sessions.split(',') unless attendee.iattend_sessions.blank?
      # puts "length"
      # puts Session.where(event_id:event_id,session_code:session_codes).length

      Session.where(event_id:event_id,session_code:session_codes).each do |session|
        credit_hours  = ''
        speaker_names = ''
        session.speakers.each do |speaker|
          speaker_names += speaker.full_name + " "
        end
        unless session.credit_hours.blank?
          credit_hours = '%.02f' % session.credit_hours
          @total_credit_hours += '%.02f' % session.credit_hours.to_f
        end
        credits_array.push [session.date, session.session_code, session.title, speaker_names, '%.02f' % session.credit_hours]
      end
      return credits_array
    end

    def generate_detailed_pdf(attendee, credits_array, full_name)
      pdf           = Prawn::Document.new(:page_layout => :landscape)

      pdf.move_down 40
      pdf.image     "./ek_scripts/pdf-generators/avma_2015_logo.png", position: :center, width:100
      pdf.move_down 20
      pdf.text      "American Veterinary Medical Association", align: :center, size: 14, font: "Verdana"
      pdf.move_down 5
      pdf.text      "CONTINUING EDUCATION CERTIFICATE

      2015 AVMA Annual Convention
      Boston, MA
      July 10 - 14, 2015


      This certifies that

      #{full_name}

      has attended #{'%.02f' % @total_credit_hours} hours of AVMA-approved continuing education credit for
      veterinary medical license renewal purposes.


      Ronald E. Banks, DVM
      Chair, Convention Management and Program Committee", align: :center, size: 11, font: "Verdana"
      pdf.move_down 5
      # pdf.text      "", align: :center, size: 14, font: "Verdana"
      pdf.move_down 10
      pdf.image     "./ek_scripts/pdf-generators/avma_2015_signature.png", position: :center, height:45
      pdf.move_down 20
      pdf.start_new_page
      pdf.table(credits_array, position: :center, column_widths:{0 => 85})

      filename = "Detailed CE Certificate for #{full_name}.pdf"

      pdf.render_file "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
      "/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
    end

    def generate_simple_pdf(attendee, credits_array, full_name)
      pdf           = Prawn::Document.new
      pdf.move_down 40
      pdf.image     "./ek_scripts/pdf-generators/avma_2015_logo.png", position: :center, width:100
      pdf.move_down 20
      pdf.text      "American Veterinary Medical Association", align: :center, size: 14, font: "Verdana"
      pdf.move_down 5
      pdf.text      "CERTIFICATE OF ATTENDANCE

      This certifies that

      #{attendee.first_name} #{attendee.last_name}

      attended the 2015 AVMA Annual Convention in
      Boston, MA
      July 10 - 14, 2015


      Full participation qualifies for up to 47 contact hours of
      AVMA-approved continuing education credit.", align: :center, size: 11, font: "Verdana"
      pdf.move_down 20
      pdf.image     "./ek_scripts/pdf-generators/avma_2015_signature.png", position: :center, height:45
      pdf.move_down 20
      pdf.text      " Ronald E. Banks, DVM

      Chair, Convention Management and Program Committee", align: :center, size: 11, font: "Verdana"
      pdf.move_down 10

      filename = "Certificate of Attendance for #{full_name}.pdf"

      pdf.render_file "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"

      "/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
      # send_pdf(pdf)
      # send_data pdf.render, filename: "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}", type: "application/pdf"

    end

    attendees = Attendee.where(event_id:48, last_name:params[:last_name], account_code:params[:registration_id])
    cert_type = params[:cert_type]

    respond_to do |format|
      if attendees.length > 0
        attendee = attendees.first

        full_name     = ""
        full_name     = "#{attendee.first_name} #{attendee.last_name}" unless attendee.first_name.blank? || attendee.last_name.blank?
        credits_array = getCreditsTableDataAsArray(48, attendee)
        puts credits_array
        puts @total_credit_hours
        if cert_type === "Detailed CE Certificate"
          format.html {redirect_to(generate_detailed_pdf(attendee, credits_array, full_name)) }
        else
          format.html {redirect_to(generate_simple_pdf(attendee, credits_array, full_name)) }
        end

        # format.html { redirect_to("/download_ce_certificate", :notice => "Attendee exists")}
      else
        format.html {redirect_to("/download_ce_certificate", :alert => "Could not find attendee with given last name and Registration ID. Please try again.")}
      end
    end
  end

  def generate_acvs_certificate(params)

    @total_credit_hours = 0

    def send_pdf(pdf)
        send_data pdf.render, type: "application/pdf"
    end

    def generate_pdf(attendee, credits_array)

      first_n = "#{attendee.first_name}" + "\s" * (44 - attendee.first_name.length)
      last_n = "#{attendee.last_name}" + "\s" * (44 - attendee.last_name.length)

      header = "<b>2015 ACVS Surgery Summit • October 21-24 • Nashville, TN
        CERTIFICATE OF ATTENDANCE - <color rgb='#F40200'>Program # 24-17781</color></b>"

      description = "Race provider #24: <i>Course meets the requirements for 291 continuing education credit in jurisdictions which recognize AAVSB's RACE approval; however participants should be aware that some boards have limitations on the number of hours accepted in certain categories and/or restrictions on certain methods of delivery of continuing education. <b>Copies of this form should be submitted to your state licensure agency, or other group, as proof of attendance. Do not return forms to ACVS.</b></i>\n\n"

      form = "<b>Print your name as it appears on your badge.

        First Name </b><u>#{first_n}</u> <b>Middle Initial <u>#{' ' * 20}</u> Last Name</b> <u>#{last_n}</u>

        <b>Address <u>#{' ' * 49}</u> City <u>#{' ' * 40}</u> State <u>#{' ' * 10}</u> Zip Code <u>#{' ' * 22}</u>

        Licensure Information 1) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u> 2) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u></b>\n"

      footer_top = "By my signature I certify the above is information is accurate. <u>#{' ' * 40}</u> <u>#{' ' * 20}</u>


      Authorized by: <u>#{' ' * 40}</u> <u>\s\s\s#{Time.now.strftime('%m/%d/%Y')}\s\s\s</u>\n\n"

      footer_bottom = "<i>American College of Veterinary Surgeons • 19785 Crystal Rock Dr, Ste. 305, Germantown, MD 20874 • surgerysummit@acvs.org</i>\n\n"


      pdf           = Prawn::Document.new

      pdf.move_down 20
      pdf.text      header, align: :center, size: 14, font: "Times-Roman", inline_format: true
      pdf.move_down 5
      pdf.text_box  description + form, inline_format: true, width: 510, at:[15,660], size: 9
      pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[125,530], size: 8
      pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[225,530], size: 8
      pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[295,530], size: 8
      pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[395,530], size: 8
      pdf.move_down 160

      pdf.table(credits_array, position: :center, column_widths:{0 => 85, 2 => 190}, cell_style: {size:8, :inline_format => true }) do
        cells.padding = 5
        style(row(0), font_style: :bold, background_color: 'E0E0E0')
      end

      if credits_array.length===1
        pdf.move_down 15
        pdf.text "No sessions have been attended yet.", align: :center, size: 10, font: "Times-Roman"
      end
      pdf.start_new_page

      pdf.text_box footer_top, inline_format: true, width: 510, at:[15,680], size: 11
      pdf.text_box footer_bottom, inline_format: true, width: 510, at:[30,600], size: 8

      pdf.text_box '<i>Surgery Summit Attendee Signature</i>', inline_format: true, width: 510, at:[310,665], size: 8
      pdf.text_box '<i>Date</i>', inline_format: true, width: 510, at:[460,665], size: 8
      pdf.text_box 'Charles E. DeCamp, President', inline_format: true, width: 510, at:[90,630], size: 8
      pdf.text_box 'Date', inline_format: true, width: 510, at:[240,630], size: 8

      pdf.image     "./ek_scripts/pdf-generators/acvs_sig.png", at:[95,655], width:100

      filename = "Attendence Certificate for #{attendee.full_name}.pdf"

      ensure_directory_exists File.dirname(Rails.root.join('public','event_data',attendee.event_id.to_s,'generated_pdfs',filename))

      pdf.render_file "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
      "/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
    end

    attendees = Attendee.where(event_id:65, last_name:params[:last_name], account_code:params[:registration_id])

    respond_to do |format|
      if attendees.length > 0
        attendee      = attendees.first
        credits_array = return_credits_table_array(65, attendee)
        format.html {redirect_to(generate_pdf(attendee, credits_array)) }
      else
        format.html {redirect_to("/download_acvs_ce_certificate", :alert => "Could not find attendee with given last name and Registration ID. Please try again.")}
      end
    end

  end

  def generate_mte_certificate(params)

    @total_credit_hours = 0

    def send_pdf(pdf)
        send_data pdf.render, type: "application/pdf"
    end

    def generate_pdf(attendee, credits_array)

      first_n = "#{attendee.first_name}" + "\s" * (44 - attendee.first_name.length)
      last_n = "#{attendee.last_name}" + "\s" * (44 - attendee.last_name.length)

      header = "<b>2015 MTE • November 10th • New York City
        CERTIFICATE OF ATTENDANCE - <color rgb='#F40200'>Program # 24-17781</color></b>"

      description = "Race provider #24: <i>Course meets the requirements for 291 continuing education credit in jurisdictions which recognize AAVSB's RACE approval; however participants should be aware that some boards have limitations on the number of hours accepted in certain categories and/or restrictions on certain methods of delivery of continuing education. <b>Copies of this form should be submitted to your state licensure agency, or other group, as proof of attendance. Do not return forms to MTE.</b></i>\n\n"

      form = "<b>Print your name as it appears on your badge.

        First Name </b><u>#{first_n}</u> <b>Middle Initial <u>#{' ' * 20}</u> Last Name</b> <u>#{last_n}</u>

        <b>Address <u>#{' ' * 49}</u> City <u>#{' ' * 40}</u> State <u>#{' ' * 10}</u> Zip Code <u>#{' ' * 22}</u>

        Licensure Information 1) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u> 2) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u></b>\n"

      footer_top = "By my signature I certify the above is information is accurate. <u>#{' ' * 40}</u> <u>#{' ' * 20}</u>


      Authorized by: <u>#{' ' * 40}</u> <u>\s\s\s#{Time.now.strftime('%m/%d/%Y')}\s\s\s</u>\n\n"

      footer_bottom = "<i>Meetings Technology Expo • New York City</i>\n\n"


      pdf           = Prawn::Document.new

      pdf.text      header, align: :center, size: 14, font: "Times-Roman", inline_format: true
      pdf.move_down 5
      pdf.text_box  description + form, inline_format: true, width: 510, at:[15,660], size: 9
      pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[125,530], size: 8
      pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[225,530], size: 8
      pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[295,530], size: 8
      pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[395,530], size: 8
      pdf.move_down 160

      pdf.image     "./ek_scripts/pdf-generators/mte.png", position: :center, width:100

      pdf.table(credits_array, position: :center, column_widths:{0 => 85, 2 => 190}, cell_style: {size:8, :inline_format => true }) do
        cells.padding = 5
        style(row(0), font_style: :bold, background_color: 'E0E0E0')
      end

      if credits_array.length===1
        pdf.move_down 15
        pdf.text "No sessions have been attended yet.", align: :center, size: 10, font: "Times-Roman"
      end
      pdf.start_new_page

      pdf.text_box footer_top, inline_format: true, width: 510, at:[15,680], size: 11
      pdf.text_box footer_bottom, inline_format: true, width: 510, at:[30,600], size: 8

      pdf.text_box '<i>MTE Attendee Signature</i>', inline_format: true, width: 510, at:[330,665], size: 8
      pdf.text_box '<i>Date</i>', inline_format: true, width: 510, at:[460,665], size: 8
      pdf.text_box 'Charles E. DeCamp, President', inline_format: true, width: 510, at:[90,630], size: 8
      pdf.text_box 'Date', inline_format: true, width: 510, at:[240,630], size: 8

      pdf.image     "./ek_scripts/pdf-generators/acvs_sig.png", at:[95,655], width:100

      filename = "Attendence Certificate for #{attendee.full_name}.pdf"

      ensure_directory_exists File.dirname(Rails.root.join('public','event_data',attendee.event_id.to_s,'generated_pdfs',filename))

      pdf.render_file "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
      "/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
    end

    attendees = Attendee.where(event_id:72, last_name:params[:last_name], account_code:params[:registration_id])

    respond_to do |format|
      if attendees.length > 0
        attendee      = attendees.first
        credits_array = return_credits_table_array(72, attendee)
        format.html {redirect_to(generate_pdf(attendee, credits_array)) }
      else
        format.html {redirect_to("/download_mte_ce_certificate", :alert => "Could not find attendee with given last name and Registration ID. Please try again.")}
      end
    end

  end

  def return_credits_table_array(event_id, attendee)
    credits_array = []
    credits_array << ["Date","Session ID","Session Name","Speaker Name","Credit Hours"]
    session_codes = []
    session_codes = attendee.iattend_sessions.split(',') unless attendee.iattend_sessions.blank?

    Session.where(event_id:event_id,session_code:session_codes).each do |session|
      credit_hours  = ''
      speaker_names = []
      session.speakers.each {|s| speaker_names << s.full_name}
      speaker_names = speaker_names.join(' ')

      unless session.credit_hours.blank?
        credit_hours = '%.02f' % session.credit_hours
        @total_credit_hours += session.credit_hours.to_f
      end
      credits_array.push [session.date, session.session_code, session.title, speaker_names, '%.02f' % session.credit_hours]
    end
    return credits_array
  end

  def generate_acvs_certificate_remote

    puts "generate acvs cert remote"
    if access_allowed? && params['api_proxy_key'] === API_PROXY_KEY
      set_access_control_headers
      headers['Content-Type'] = "text/javscript; charset=utf8"
      account_code            = params['account_code']
      event_id                = params['event_id']

      @total_credit_hours = 0

      def send_pdf(pdf)
          send_data pdf.render, type: "application/pdf"
      end

      def generate_pdf(attendee, credits_array)

        first_n = "#{attendee.first_name}" + "\s" * (44 - attendee.first_name.length)
        last_n = "#{attendee.last_name}" + "\s" * (44 - attendee.last_name.length)

        header = "<b>2015 ACVS Surgery Summit • October 21-24 • Nashville, TN
          CERTIFICATE OF ATTENDANCE - <color rgb='#F40200'>Program # 24-17781</color></b>"

        description = "Race provider #24: <i>Course meets the requirements for 291 continuing education credit in jurisdictions which recognize AAVSB's RACE approval; however participants should be aware that some boards have limitations on the number of hours accepted in certain categories and/or restrictions on certain methods of delivery of continuing education. <b>Copies of this form should be submitted to your state licensure agency, or other group, as proof of attendance. Do not return forms to ACVS.</b></i>\n\n"

        form = "<b>Print your name as it appears on your badge.

          First Name </b><u>#{first_n}</u> <b>Middle Initial <u>#{' ' * 20}</u> Last Name</b> <u>#{last_n}</u>

          <b>Address <u>#{' ' * 49}</u> City <u>#{' ' * 40}</u> State <u>#{' ' * 10}</u> Zip Code <u>#{' ' * 22}</u>

          Licensure Information 1) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u> 2) <u>#{' ' * 31}</u> <u>#{' ' * 31}</u></b>\n"

        footer_top = "By my signature I certify the above is information is accurate. <u>#{' ' * 40}</u> <u>#{' ' * 20}</u>


        Authorized by: <u>#{' ' * 40}</u> <u>\s\s\s#{Time.now.strftime('%m/%d/%Y')}\s\s\s</u>\n\n"

        footer_bottom = "<i>American College of Veterinary Surgeons • 19785 Crystal Rock Dr, Ste. 305, Germantown, MD 20874 • surgerysummit@acvs.org</i>\n\n"


        pdf           = Prawn::Document.new

        pdf.move_down 20
        pdf.text      header, align: :center, size: 14, font: "Times-Roman", inline_format: true
        pdf.move_down 5
        pdf.text_box  description + form, inline_format: true, width: 510, at:[15,660], size: 9
        pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[125,530], size: 8
        pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[225,530], size: 8
        pdf.text_box '<b><i>State of Licensure</i></b>', inline_format: true, width: 510, at:[295,530], size: 8
        pdf.text_box '<b><i>License #</i></b>', inline_format: true, width: 510, at:[395,530], size: 8
        pdf.move_down 160

        pdf.table(credits_array, position: :center, column_widths:{0 => 85, 2 => 190}, cell_style: {size:8, :inline_format => true }) do
          cells.padding = 5
          style(row(0), font_style: :bold, background_color: 'E0E0E0')
        end

        if credits_array.length===1
          pdf.move_down 15
          pdf.text "No sessions have been attended yet.", align: :center, size: 10, font: "Times-Roman"
        end
        pdf.start_new_page

        pdf.text_box footer_top, inline_format: true, width: 510, at:[15,680], size: 11
        pdf.text_box footer_bottom, inline_format: true, width: 510, at:[30,600], size: 8

        pdf.text_box '<i>Surgery Summit Attendee Signature</i>', inline_format: true, width: 510, at:[310,665], size: 8
        pdf.text_box '<i>Date</i>', inline_format: true, width: 510, at:[460,665], size: 8
        pdf.text_box 'Charles E. DeCamp, President', inline_format: true, width: 510, at:[90,630], size: 8
        pdf.text_box 'Date', inline_format: true, width: 510, at:[240,630], size: 8

        pdf.image     "./ek_scripts/pdf-generators/acvs_sig.png", at:[95,655], width:100

        filename = "Attendence Certificate for #{attendee.full_name}.pdf"

        ensure_directory_exists File.dirname(Rails.root.join('public','event_data',attendee.event_id.to_s,'generated_pdfs',filename))

        pdf.render_file "./public/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
        "/event_data/#{attendee.event_id}/generated_pdfs/#{filename}"
      end

      attendees = Attendee.where(event_id:event_id,account_code:account_code)

      respond_to do |format|
        if attendees.length > 0
          attendee      = attendees.first
          credits_array = return_credits_table_array(65, attendee)
          format.html {redirect_to(generate_pdf(attendee, credits_array)) }
        end
      end

    else
      head :forbidden
    end

  end

  def generate_motm_apa_main_conference_pdf
    remote_generate_pdf {|a| GenerateApaMainConferencePdfAndReturnUrl.new(a).call}
  end

  def generate_motm_apa_saturday_pdf
    remote_generate_pdf {|a| GenerateApaSaturdayPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_apa_sunday_pdf
    remote_generate_pdf {|a| GenerateApaSundayPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_apa_wednesday_pdf
    remote_generate_pdf {|a| GenerateApaWednesdayPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_shrm_main_conference_pdf
    remote_generate_pdf {|a| GenerateShrmMainConferencePdfAndReturnUrl.new(a).call}
  end

  def generate_motm_nasba_main_conference_pdf
    remote_generate_pdf {|a| GenerateNasbaMainConferencePdfAndReturnUrl.new(a).call}
  end

  def generate_motm_hrci_recertification_credit_form_pdf
    remote_generate_pdf {|a| GenerateHrciRecertificationCreditFormPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_ihrm_main_conference_pdf
    remote_generate_pdf {|a| GenerateIhrmMainConferencePdfAndReturnUrl.new(a).call}
  end

  def generate_motm_ihrm_saturday_pdf
    remote_generate_pdf {|a| GenerateIhrmSaturdayPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_ihrm_sunday_pdf
    remote_generate_pdf {|a| GenerateIhrmSundayPdfAndReturnUrl.new(a).call}
  end

  def generate_motm_ihrm_wednesday_pdf
    remote_generate_pdf {|a| GenerateIhrmWednesdayPdfAndReturnUrl.new(a).call}
  end

  def generate_fiserv_certificate_pdf
    remote_generate_pdf {|a| Fiserv::GenerateCeCertificateAndReturnUrl.new(a).call}
  end

  ## Auto Generated Methods Start ## Do Not Delete This Comment

  def event_314_generate_certificate_of_completion
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event314::GenerateCertificateOfCompletion.new(a,jd).call}
  end

  def event_322_generate_certificate_of_attendance_2019
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event322::GenerateCertificateOfAttendance2019.new(a,jd).call}
  end

  def event_304_generate_certificate_of_completion
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event304::GenerateCertificateOfCompletion.new(a,jd).call}
  end

  def event_304_generate_certificate_of_attendance_2019
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event304::GenerateCertificateOfAttendance2019.new(a,jd).call}
  end

  def event_293_generate_detailed_ce_certificate
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event293::GenerateDetailedCeCertificate.new(a,jd).call}
  end

  def event_293_generate_certificate_of_attendance
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event293::GenerateCertificateOfAttendance.new(a,jd).call}
  end

  def event_292_generate_sdafp_certificate_of_attendance
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event292::GenerateSdafpCertificateOfAttendance.new(a,jd).call}
  end


  def event_269_generate_certificate_of_survey_completion
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateCertificateOfSurveyCompletion.new(a,jd).call}
  end



  def event_269_generate_test__4
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTest4.new(a,jd).call}
  end

  def event_269_generate_test_certificate_5
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTestCertificate5.new(a,jd).call}
  end

  def event_269_generate_test_cerificate_4
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTestCerificate4.new(a,jd).call}
  end

  def event_269_generate_test_cerificate
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTestCerificate.new(a,jd).call}
  end

  def event_269_generate_test_certificate_3
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTestCertificate3.new(a,jd).call}
  end

  def event_269_generate_the_main_certificate
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateTheMainCertificate.new(a,jd).call}
  end

  def event_269_generate_certificate_of_completion
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateCertificateOfCompletion.new(a,jd).call}
  end

  def event_269_generate_certificate_of_test
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event269::GenerateCertificateOfTest.new(a,jd).call}
  end

  def event_263_generate_certificate_of_attendance001
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event263::GenerateCertificateOfAttendance001.new(a,jd).call}
  end

  def event_263_generate_certificate_of_test
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event263::GenerateCertificateOfTest.new(a,jd).call}
  end

  def event_263_generate_certificate_of_completion
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event263::GenerateCertificateOfCompletion.new(a,jd).call}
  end

  def event_263_generate_certificate_of_attendance
    @certificate_id = params[:id]
    remote_generate_pdf_with_variables {|a,jd| Event263::GenerateCertificateOfAttendance.new(a,jd).call}
  end

  def event_268_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event268::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_267_generate_certificate_of_completion
    remote_generate_pdf {|a| Event267::GenerateCertificateOfCompletion.new(a).call}
  end

  def event_240_generate_certificate_of_completion
    remote_generate_pdf {|a| Event240::GenerateCertificateOfCompletion.new(a).call}
  end

  def event_247_generate_detailed_continuing_education_certificate
    remote_generate_pdf {|a| Event247::GenerateDetailedContinuingEducationCertificate.new(a).call}
  end

  def event_247_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event247::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_201_generate_detailed_continuing_education_certificate
    remote_generate_pdf {|a| Event201::GenerateDetailedContinuingEducationCertificate.new(a).call}
  end

  def event_201_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event201::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_208_generate_detailed_certificate_of_attendance
    remote_generate_pdf {|a| Event208::GenerateDetailedCertificateOfAttendance.new(a).call}
  end

  def event_208_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event208::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_227_generate_certificate_of_completion
    remote_generate_pdf {|a| Event227::GenerateCertificateOfCompletion.new(a).call}
  end

  def event_214_generate_cpe_certificate
    remote_generate_pdf {|a| Event214::GenerateCpeCertificate.new(a).call}
  end

  def event_205_generate_certificate_of_completion
    remote_generate_pdf {|a| Event205::GenerateCertificateOfCompletion.new(a).call}
  end

  def event_187_generate_detailed_continuing_education_certificate
    remote_generate_pdf {|a| Event187::GenerateDetailedContinuingEducationCertificate.new(a).call}
  end

  def event_187_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event187::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_181_generate_certificate_of_completion
    remote_generate_pdf {|a| Event181::GenerateCertificateOfCompletion.new(a).call}
  end

  def event_182_generate_fiserv_cpe_credit_certificate
    remote_generate_pdf {|a| Event182::GenerateFiservCpeCreditCertificate.new(a).call}
  end

  def event_158_generate_detailed_certificate_of_attendance
    remote_generate_pdf {|a| Event158::GenerateDetailedCertificateOfAttendance.new(a).call}
  end

  def event_158_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event158::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_161_generate_bcbs_certificate_of_completion
    remote_generate_pdf {|a| Event161::GenerateBcbsCertificateOfCompletion.new(a).call}
  end

  def event_122_generate_detailed_continuing_education_certificate
    remote_generate_pdf {|a| Event122::GenerateDetailedContinuingEducationCertificate.new(a).call}
  end

  def event_122_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event122::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_134_generate_fiserv_cpe_credit_certificate
    remote_generate_pdf {|a| Event134::GenerateFiservCpeCreditCertificate.new(a).call}
  end

  def event_118_generate_detailed_certificate_of_attendance
    remote_generate_pdf {|a| Event118::GenerateDetailedCertificateOfAttendance.new(a).call}
  end

  def event_118_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event118::GenerateCertificateOfAttendance.new(a).call}
  end

  def event_119_generate_bcbs_certificate_of_completion
    remote_generate_pdf {|a| Event119::GenerateBcbsCertificateOfCompletion.new(a).call}
  end

  def event_126_generate_aap_documentation_of_attendance
    remote_generate_pdf {|a| Event126::GenerateAapDocumentationOfAttendance.new(a).call}
  end

  def event_171_generate_aap_documentation_of_attendance
    remote_generate_pdf {|a| Event171::GenerateAapDocumentationOfAttendance.new(a).call}
  end

  def event_114_generate_risk_intelligence_certificate
    remote_generate_pdf {|a| Event114::GenerateRiskIntelligenceCertificate.new(a).call}
  end

  def event_107_generate_attendance_certificate
    remote_generate_pdf {|a| Event107::GenerateAttendanceCertificate.new(a).call}
  end

  def event_78_generate_detailed_continuing_education_certificate
    remote_generate_pdf {|a| Event78::GenerateDetailedContinuingEducationCertificate.new(a).call}
  end

  def event_78_generate_certificate_of_attendance
    remote_generate_pdf {|a| Event78::GenerateCertificateOfAttendance.new(a).call}
  end

  # Public API
  def get_certificate
    # Decrypt :id, :expiry
    # params: certificate_id, account_code, expiry, name="certificate_of_survey_completion", event_id
    # Please note: link expiry has been set to 30 days of generation
    begin
      @verifier = ActiveSupport::MessageVerifier.new(ENV['SALT'])
      event = Event.find params[:e]
      timestamp = @verifier.verify params[:expiry]
      expiry = DateTime.strptime(timestamp.to_s,'%s').in_time_zone(event.timezone)
      curr_time = Time.now.in_time_zone(event.timezone)
      if curr_time < expiry
        @certificate_id = @verifier.verify params[:id]
        name = params[:type]
        certificate_module = "Event#{event.id}::Generate#{name.split('_').map(&:capitalize).join}".constantize
        remote_generate_pdf_with_variables {|a,jd| certificate_module.send(:new, a,jd).call}
      else
        render plain: "Invalid link or the link has expired."
      end
    rescue => exception
      p exception
      p exception.message
      render plain: "Invalid link or the link has expired."
    end
  end
  ## Auto Generated Methods End

  def options
    puts "options method hit"
    if access_allowed?
      puts "access allowed hit"
      set_access_control_headers
      head :ok
    else
      puts "access forbiddon"
      head :forbidden
    end
  end

  private

  def remote_generate_pdf
    attendees = Attendee.where(event_id:params['event_id'], account_code:params['account_code'])

    respond_to do |format|
      if attendees.length > 0
        pdf_url = yield attendees.first
        format.html { redirect_to(pdf_url) }
      end
    end
  end

  def remote_generate_pdf_with_variables
    event_id = session[:event_id] ? session[:event_id] : params[:e]
    if !!params[:account_code]
      attendees = Attendee.where(event_id:event_id, account_code:params[:account_code])
      attendee = attendees.first
    elsif params[:attendee]
      attendee = Attendee.find_by_slug(params[:attendee])
    else
      demo_attendee = Attendee.where(event_id:event_id,
        first_name:"First Name",
        last_name:"Last Name",
        company: 'Company',
        honor_suffix:"Suffix",
        iattend_sessions: '14008,14010,13463,13237',
        slug: '11111111111',
        is_demo:true).first_or_create
      end
      # attendees = Attendee.where(event_id:263, account_code:'E339A38C-3EEB-4D86-945C-2E7BE59D2063')
    @certificate = CeCertificate.find @certificate_id
    @json_data = JSON.parse @certificate.json
    
    respond_to do |format|
      if !attendee.blank?
        pdf_url = yield(attendee, @json_data)
        format.html { redirect_to(pdf_url) }
      elsif params[:account_code].blank? && params[:attendee].blank?
        pdf_url = yield(demo_attendee, @json_data)
        format.html { redirect_to(pdf_url) }
      end
    end
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin']  = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age']       = '1000'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,x-requested-by,Content-Type'
  end

  def access_allowed?
    return true
  end

  def get_or_create_certificate_settings
    setting_type = SettingType.find_by_name "certificate_settings"
    settings = Setting.where(event_id: session[:event_id], setting_type_id: setting_type.id)
    if settings.blank?
      json_data = {
        display_company: false,
        display_total_hours: false,
        name_position: 0,
        name_font_size: 0,
        company_position: 0,
        company_font_size: 0,
        total_hours_position: 0,
        total_hours_font_size: 0
      }
      setting = Setting.create(event_id: session[:event_id], setting_type_id: setting_type.id, json: json_data.to_json)
    else
      setting = settings.first
    end
    return setting
  end

end
