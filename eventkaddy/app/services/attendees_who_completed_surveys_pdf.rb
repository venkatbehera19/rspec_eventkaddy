class AttendeesWhoCompletedSurveysPdf

  def initialize args={}
    @min_surveys_to_complete = args[:min_surveys_to_complete] || 5
    @event_id                = args[:event_id] || raise("Event ID required.")
  end
  
  def create_pdf
    ensure_directory_exists
    pdf = Prawn::Document.new
    attach_pdf_contents pdf
    pdf.render_file path
    url
  end

  def url
    "/event_data/#{@event_id}/pdf_reports/#{filename}" # note, not the same as #path
  end

  def path
    "./public/event_data/#{@event_id}/pdf_reports/#{filename}"
  end

  def attach_pdf_contents pdf
    table_content = attendees
    if table_content.blank?
      pdf.move_down 255
      pdf.text "No attendee has yet completed #{@min_surveys_to_complete} surveys.", align: :center, size: 40, font: "Times-Roman"
    else
      pdf.table(
        table_content,
        position: :center,
        column_widths: { 0 => 270, 1 => 270 },
        cell_style: {
          inline_format: true,
          border_width:  0.3,
          valign:        :center,
          align:         :center,
          font_style:    :bold
        }
      ) do
        cells.padding = 2
      end
    end
  end

  def filename
    "#{Event.find(@event_id).name.downcase.gsub(/\s/,"_")}_attendees_who_completed_surveys.pdf"
  end

  def dirname
    File.dirname Rails.root.join( path )
  end

  def ensure_directory_exists
    FileUtils.mkdir_p( dirname ) unless File.directory?( dirname )
  end

  def attendees
    ary = Attendee.
      select(
        'first_name,
        last_name,
        account_code,
        COUNT(survey_responses.id) AS surveys_completed_count'
      ).
      where(event_id: @event_id).
      group(:attendee_id).
      joins(:survey_responses).
      map {|a| 
        next unless a.surveys_completed_count >= @min_surveys_to_complete
        "<font size='20'>#{a.full_name}</font>\n 
        Registration ID: #{a.account_code}\n\n"
      }.
      compact

      # ugly, but need to get it into this format somehow.
      by_twos_array = []
      ary.each_with_index {|a, i|
        by_twos_array << [ary[i], ary[i+1]] if i.even?
      }
      by_twos_array
  end

end

# AttendeesWhoCompletedSurveysPdf.new( event_id: 82, min_surveys_to_complete:2 ).create_pdf
