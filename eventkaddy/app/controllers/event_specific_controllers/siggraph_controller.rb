class SiggraphController < ApplicationController
  # load_and_authorize_resource
  def siggraph_session_report

    @event_id = session[:event_id]

    respond_to do |format|
      format.xlsx { render :action => :siggraph_session_report, disposition: "attachment", filename: "siggraph_2015_sessions_for_usb.xlsx" }
    end
  end

  def generate_siggraph_rooms_schedules

    event_id = session[:event_id]

    def createDirectoryUnlessItExists(dirname)
      unless File.directory?(dirname) then FileUtils.mkdir_p(dirname); end
    end

    dirname = File.dirname(Rails.root.join('public','event_data', event_id.to_s,'generated_pdfs','pdf.pdf'))
    createDirectoryUnlessItExists(dirname)

    generate_pdf_cmd     = Rails.root.join('ek_scripts','pdf-generators',"siggraph-rooms.rb \"#{event_id}\"")

    @generate_pdf_result = `ROO_TMP='/tmp' ruby #{generate_pdf_cmd} 2>&1`

    Rails::logger.debug "\n--------- import script output ---------\n\n #{@generate_pdf_result} \n------------------- \n"

    respond_to do |format|
      format.html {redirect_to("/events/configure/#{event_id}", :notice => "Successfully generated room pdfs.")}
      # else
      #   format.html {redirect_to("/email_ce_certificate", :alert => "Could not find attendee with given last name and Registration ID. Please try again.")}
      # end
    end

  end

end