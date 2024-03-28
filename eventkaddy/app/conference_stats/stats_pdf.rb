class StatsPdf

  def initialize event, primary_color="317eac", secondary_color="317eac", tertiary_color="000000"
    @event           = event
    @event_id        = @event.id
    @primary_color   = primary_color
    @secondary_color = secondary_color
    @tertiary_color  = tertiary_color
    @start_height    = 700
    @height          = @start_height
    @line_height     = 20
    @pdf             = Prawn::Document.new(prawn_options)
  end

  def call
    return_pdf
  end

  private

  attr_reader :event, :event_id, :pdf

  def dirname
    File.dirname Rails.root.join('public','event_data',event_id.to_s,'cms_pdfs',filename)
  end

  def ensure_directory_exists
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def return_pdf
    attach_pdf_contents(pdf)
    ensure_directory_exists
    pdf.render_file("./public/event_data/#{event_id}/cms_pdfs/#{filename}")
    "/event_data/#{event_id}/cms_pdfs/#{filename}"
  end

  private

  def prawn_options
    {}
  end

  def filename
    "#{event.name} Statistics #{Date.today.to_s}.pdf"
  end	

  def reset_height
    @height = @start_height
  end

  def down_a_line(line_height = @line_height)
    @height = @height - line_height
    new_page if @height < 20
    @height
  end

  def new_page
    pdf.start_new_page
    reset_height
  end

  def attach_pdf_contents(pdf)

    db = DatabaseStats.new event_id

    subheading = ->(text) { 
      pdf.text_box "<color rgb='#{@secondary_color}'>#{text}</color>",
                   width:         510,
                   at:            [0, down_a_line(40)],
                   size:          18,
                   align:         :left,
                   font_style:    :bold,
                   inline_format: true
    }
    stat = ->(title, stat) {
      pdf.text_box "<color rgb='#{@tertiary_color}'><b>#{title}</b>: #{stat}</color>",
                   width:         510,
                   at:            [10, down_a_line(25)],
                   size:          13,
                   align:         :left,
                   inline_format: true
    }

    # keeping this here as quick example of how to do an image
    # pdf.image "./ek_scripts/pdf-generators/fiserv_banner.png", at:[0, @height], width:730

    pdf.text_box "<color rgb='#{@primary_color}'>#{event.name} Statistics</color>",
                 width:         510,
                 at:            [0, @height],
                 size:          24,
                 align:         :center,
                 font_style:    :bold,
                 inline_format: true


    subheading["General"]

    stat["Sessions Listed",    db.sessions_listed]
    stat["Exhibitors Listed",  db.exhibitors_listed]
    stat["Conference Notes",   db.conference_notes_listed]
    stat["Attendees Listed",   db.attendees_listed]
    stat["Notifications Sent", db.push_notifications_sent]
    stat["Notes Taken",        db.notes_taken]
    stat["Messages Sent",      db.messages_sent]

    subheading["Logins"]

    stat["Total Logins", db.attendees_logins]
    down_a_line

    db.login_devices.each {|d| stat[d[:device], d[:count]]}
    down_a_line

    stat["Unique Logins", db.unique_logins]
    down_a_line

    db.unique_login_devices.each {|d| stat[d[:device], d[:count]]}

    new_page

    subheading["Generated PDFs"]

    db.get_generated_certificate_names.each {|c| stat[c[:name], c[:count]]}

    subheading["Surveys"]

    db.surveys_completed.each {|s| stat[s[:title] + " Responses", s[:survey_responses_count]]}

    subheading["Feedback"]

    stat["Session Feedback", db.session_feedback]
    stat["Speaker Feedback", db.speaker_feedback]

    settings = Setting.return_cms_settings event_id
    unless settings.method("hide_statistics_page_game").call

      subheading["Game"]

      db.badges_completed.each do |b|
        stat["Attendees who completed #{b[:badges_completed]} badge#{"s" if b[:badges_completed]!=1}", b[:attendee_count]]
      end
    end

  end
end
