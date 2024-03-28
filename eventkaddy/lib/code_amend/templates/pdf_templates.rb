module CodeAmend
  module PdfTemplates

    def self.create_generator_route event_id, name
      method_name        = "event_#{event_id}_generate_#{name}"
      generate_pdf_route = Line.new "get 'ce_credits/#{method_name}' => 'ce_credits##{method_name}'", 1
      lines              = Lines.new [generate_pdf_route]
      ce_routes          = Code.new Rails.root.join('config/routes', 'ce_credits_routes.rb')
      unless ce_routes.line_exists? generate_pdf_route
        ce_routes.append_to_last_block lines 
        ce_routes.write
        puts "SUCCESS: Wrote generator route".green
      else
        puts "WARN: Line already existed for pdf generator, did not write.".yellow
      end
    end

    def self.remove_route event_id, name
      method_name        = "event_#{event_id}_generate_#{name}"
      generate_pdf_route = Line.new "get 'ce_credits/#{method_name}' => 'ce_credits##{method_name}'", 1
      lines              = Lines.new [generate_pdf_route]
      ce_routes          = Code.new Rails.root.join('config/routes', 'ce_credits_routes.rb')
      if ce_routes.line_exists? generate_pdf_route
        ce_routes.remove lines 
        ce_routes.write
        puts "SUCCESS: Removed certificate route".green
      else
        puts "WARN: Line does not exist for pdf generator, Cannot remove.".yellow
      end
    end

    def self.create_ce_credits_require event_id, name
      require_statement = Lines.new(
        [
          Line.new(
            "require_relative '../../app/services/pdf_generators/event_#{event_id}/generate_#{name.downcase}.rb'"
          )
        ]
      )

      ce_credit_pdfs_initializer = Code.new(
        Rails.root.join(
          'config/initializers',
          'ce_credit_pdfs.rb'
        )
      )

      unless ce_credit_pdfs_initializer.line_exists? require_statement.at_index(0)
        ce_credit_pdfs_initializer.append_after "## Auto Generated Requires Start ## Do Not Delete This Comment", require_statement
        ce_credit_pdfs_initializer.write
        puts "SUCCESS: Wrote require statement in ce pdfs initializer for generator".green
      else
        puts "WARN: Require statement already existed in ce initializer for generator".yellow
      end
    end

    def self.remove_credits_require event_id, name
      require_statement = Lines.new(
        [
          Line.new(
            "require_relative '../../app/services/pdf_generators/event_#{event_id}/generate_#{name.downcase}.rb'"
          )
        ]
      )

      ce_credit_pdfs_initializer = Code.new(
        Rails.root.join(
          'config/initializers',
          'ce_credit_pdfs.rb'
        )
      )

      if ce_credit_pdfs_initializer.line_exists? require_statement.at_index(0)
        ce_credit_pdfs_initializer.remove require_statement
        ce_credit_pdfs_initializer.write
        puts "SUCCESS: Removed require statement in ce pdfs initializer for generator".green
      else
        puts "WARN: Require statement not existed in ce initializer for generator".yellow
      end
    end

    def self.create_ce_credits_controller_method event_id, name
      method_name = "event_#{event_id}_generate_#{name.downcase}"
      method      = Lines.new [
        Line.new("def #{method_name}", 1),
          Line.new("@certificate_id = params[:id]", 2),
          Line.new("remote_generate_pdf_with_variables {|a,jd| Event#{event_id}::Generate#{name.split('_').map(&:capitalize).join}.new(a,jd).call}", 2),
        Line.new("end", 1)
      ]
      ce_controller = Code.new Rails.root.join('app/controllers/feature_controllers', 'ce_credits_controller.rb')
      unless ce_controller.line_exists? method.at_index(0)
        ce_controller.add_block_to_class method 
        ce_controller.write
        puts "SUCCESS: Wrote generator controller method".green
      else
        puts "WARN: Line already existed for pdf generator controller method, did not write.".yellow
      end
    end

    def self.remove_ce_credits_controller_method event_id, name
      method_name = "event_#{event_id}_generate_#{name.downcase}"
      method      = Lines.new [
        Line.new("def #{method_name}", 1),
          Line.new("@certificate_id = params[:id]", 2),
          Line.new("remote_generate_pdf_with_variables {|a,jd| Event#{event_id}::Generate#{name.split('_').map(&:capitalize).join}.new(a,jd).call}", 2),
        Line.new("end", 1)
      ]
      ce_controller = Code.new Rails.root.join('app/controllers/feature_controllers', 'ce_credits_controller.rb')
      if ce_controller.line_exists? method.at_index(0)
        ce_controller.remove_block method 
        ce_controller.write
        puts "SUCCESS: Removed controller method".green
      else
        puts "WARN: Line not existed for pdf generator controller method, did not remove.".yellow
      end
    end

    def self.create_prawn_pdf_generator_class event_id, name
      path     = Rails.root.join 'app', 'services', 'pdf_generators', "event_#{event_id}"
      filename = "generate_#{name.downcase}.rb"
      filepath = Rails.root.join path, filename
      FileUtils.mkdir_p(path) unless File.directory?(path)
      unless File.exist? filepath
        File.open(filepath, "w") {|f|
f.puts "module Event#{event_id}

  class Generate#{name.split('_').map(&:capitalize).join} < GeneratePdf

    def post_initialize
      @name        = attendee.full_name
      if json_data[\"include_suffix\"] && attendee.honor_suffix
         @name = @name + ' ' + attendee.honor_suffix
      end
      @height      = 560
      @line_height = 20
    end

    private

    def prawn_options
      {:page_layout => :landscape}
    end

    # this method added for database_stats to be
    # able to find out what the filenames are. Uses
    # self becasue we don't want an instance for that;
    def self.filename_prefix
      \"#{name.gsub(/\_/, ' ')} for \"
    end

    def filename
      \"\#{self.class.filename_prefix}\#{@name}.pdf\"
    end 

    def down_a_line(line_height = @line_height)
      @height = @height - line_height
      @height
    end

    def round_down_point5 float
      (float * 2).floor / 2.0
    end

    def credits_total
      return 0 if attendee.iattend_sessions.blank?
      total_minutes = Session
        .select('start_at, end_at, date')
        .where(event_id:event_id,
               session_code:attendee.iattend_sessions
                                    .split(',')
                                    .map(&:strip))
        .to_a # dont use active record
        .uniq { |s| s.date.to_s + s.start_at.to_s + s.end_at.to_s }
        .map {|s| (s.end_at - s.start_at) / 60.0}
        .reduce(&:+)
        total_minutes = total_minutes || 0
        total_minutes / 60.0
    end

    def credits_total_with_round_off
      return 0 if attendee.iattend_sessions.blank?
      total_minutes = Session
        .select('start_at, end_at, date')
        .where(event_id:event_id,
               session_code:attendee.iattend_sessions
                                    .split(',')
                                    .map(&:strip))
        .to_a # dont use active record
        .uniq { |s| s.date.to_s + s.start_at.to_s + s.end_at.to_s }
        .map {|s| (s.end_at - s.start_at) / 60.0}
        .reduce(&:+)
      total_minutes = total_minutes || 0

      round_down_point5 total_minutes / 50.0
    end

    def session_iattend_hours
      session_codes = []
      session_codes = attendee.iattend_sessions.gsub(/\s/, '').split(',') unless attendee.iattend_sessions.blank?
      total_credit_hours = 0
      Session
        .where(event_id:event_id, session_code:session_codes)
        .order(:date)
        .each do |session|
          unless session.credit_hours.blank?
            total_credit_hours += session.credit_hours.to_f
          end
        end
      total_credit_hours
    end

    def credits_array
      credits_array = []
      session_codes = []
      session_codes = attendee.iattend_sessions.gsub(/\s/, '').split(',') unless attendee.iattend_sessions.blank?

      Session
        .where(event_id:event_id, session_code:session_codes)
        .order(:date)
        .each do |session|
          speaker_names = session.speakers.map {|s| s.full_name}.join ', '

          unless session.credit_hours.blank?
            # @total_credit_hours += session.credit_hours.to_f
            hours = session.credit_hours
          else
            hours = 0
          end

          credits_array.push [
            \"<color rgb='56617a'>\" + session.date.to_s + \"</color>\",
            \"<color rgb='56617a'>\" + session.session_code.to_s + \"</color>\",
            \"<color rgb='56617a'>\" + session.title.to_s + \"</color>\",
            \"<color rgb='56617a'>\" + speaker_names.to_s + \"</color>\",
            \"<color rgb='56617a'>\" + ('%.02f' % hours).to_s + \"</color>\"
          ]
      end
      credits_array
    end


    def table_headers
      [
        \"<color rgb='56617a'>Date</color>\",
        \"<color rgb='56617a'>Session ID</color>\",
        \"<color rgb='56617a'>Title</color>\",
        \"<color rgb='56617a'>Speaker Name(s)</color>\",
        \"<color rgb='56617a'>Credit Hours</color>\"
      ]
    end

    def find_total_hours
      t_h = 0
      case json_data[\"total_hours_type\"]
      when 1
        t_h = credits_total_with_round_off
      when 2
        t_h = credits_total
      when 3
        t_h = session_iattend_hours
      end
      if t_h.blank?
        return \"0\"
      else
        return t_h.to_s
      end
    end

    def cover_page pdf
      honor_prefix = attendee.honor_prefix ? attendee.honor_prefix : \"\"
      attendee_name = \"<color rgb='000000'>\" + honor_prefix.to_s + @name.to_s + \"</color>\"
      attendee_company = \"<color rgb='000000'>\" + attendee.company.to_s + \"</color>\"
      attendee_total_hours = \"<color rgb='000000'>\" + find_total_hours + \"</color>\"

      background_image_path = \"#{Rails.public_path}/ce-credits/#{event_id}/certificate_background/#{event_id}_#{name.downcase.gsub(' ', '_')}.png\"
      if File.file? background_image_path
        pdf.image background_image_path, at:[0,550], width:730

        pdf.text_box attendee_name, width: json_data[\"name_width\"], at:[json_data[\"name_position_x\"], json_data[\"name_position_y\"]], size: json_data[\"name_font_size\"], :align => :center, :inline_format => true

        json_data[\"display_company\"] &&  (pdf.text_box attendee_company, width: json_data[\"company_width\"], at:[json_data[\"company_position_x\"], json_data[\"company_position_y\"]], size: json_data[\"company_font_size\"], :align => :center, :inline_format => true)

        json_data[\"display_total_hours\"] && (pdf.text_box attendee_total_hours, width: json_data[\"total_hours_width\"], at:[json_data[\"total_hours_position_x\"], json_data[\"total_hours_position_y\"]], size: json_data[\"total_hours_font_size\"], :align => :center, :inline_format => true)
      else
        pdf.move_down 255
        pdf.text \"Please upload a background Image\", align: :center, size: 40, font: \"Times-Roman\"  
      end
    end

    def table_page pdf, rows
      border_image_path = \"#{Rails.public_path}/ce-credits/#{event_id}/certificate_border/#{event_id}_#{name.downcase.gsub(' ', '_')}.png\"
      File.file?(border_image_path) && (pdf.image border_image_path, at:[0,545], width:730)
      pdf.move_down 50
      pdf.indent(12)  {
        pdf.table(rows,
                  position:      :center,
                  column_widths: {0 => 80, 1 => 100, 2 => 240, 3 => 150, 4 => 50},
                  cell_style:    {size:10,
                    inline_format: true,
                    border_width:  1,
                    valign: :center,
                    border_color: 'EEEEEE'}) do
                      cells.padding = [5, 3, 10, 3]
                      style row(0), font_style: :bold, align: :center, size: 12
                      column(0).style :align => :center
                      column(1).style :align => :center
                      column(4).style :align => :center
                      rows(0..-1).each do |r|
                        r.height = 25 if r.height < 25
                      end
                    end
      }
    end

    def attach_pdf_contents(pdf)
      cover_page pdf
      if json_data[\"insert_table\"]
        table = credits_array
        cover_page pdf
        first_pass = true
        while (rows = table.shift(9)).length >= 1 || first_pass do
          first_pass = false
          pdf.start_new_page
          rows.unshift table_headers
          # rows << empty_row until rows.length > 9
          table_page pdf, rows
        end
      end
    end
  end
end"
        }
        puts "SUCCESS: wrote prawn pdf generator class.".green
      else
        puts "WARN: prawn pdf generator class file already exists.".yellow
      end
    end

    def self.remove_prawn_pdf_generator_class event_id, name
      path     = Rails.root.join 'app', 'services', 'pdf_generators', "event_#{event_id}"
      filename = "generate_#{name.downcase}.rb"
      filepath = Rails.root.join path, filename
      File.delete(filepath) if File.exist?(filepath)
      puts "SUCCESS: removed prawn pdf generator class.".green
    end

    def self.remove_pdf_email_script event_id, name
      path     = Rails.root.join 'ek_scripts', 'pdf-generators'
      filename = "#{event_id}_#{name.downcase}.rb"
      filepath = Rails.root.join path, filename
      File.delete(filepath) if File.exist?(filepath)
      puts "SUCCESS: removed pdf email script.".green
    end

    def self.create_pdf_email_script event_id, name
      path     = Rails.root.join 'ek_scripts', 'pdf-generators'
      filename = "#{event_id}_#{name.downcase}.rb"
      filepath = Rails.root.join path, filename
      FileUtils.mkdir_p(path) unless File.directory?(path)
      unless File.exist? filepath
        File.open(filepath, "w") {|f|
f.puts "require \"prawn\"
require \"prawn/table\"
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../../app/services/pdf_generators/event_#{event_id}/generate_#{name.downcase}.rb'

Eventkaddy::Application.configure do
  config.action_mailer.smtp_settings = {
    :address   => \"smtp.mandrillapp.com\",
    :port      => 587,
    :user_name => 'dave@soma-media.com',
    :password  => ENV['MAILER_PASS']
  }
end

ActiveRecord::Base.establish_connection(
  :adapter  => \"mysql2\",
  :host     => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

event_id, attendee_id, json_data, mailer_data = ARGV[0], ARGV[1], ARGV[4], ARGV[5]

def send_email?
  ARGV[2] === \"true\" ? true : false
end
p ARGV
attendee     = Attendee.find attendee_id
mailer       = JSON.parse mailer_data
subject_text = mailer[\"subject\"]
content      = mailer[\"content\"].gsub('{{attendee}}', attendee.first_name)
if json_data.blank?
  path     = './public' + Event#{event_id}::Generate#{name.split('_').map(&:capitalize).join}.new(attendee).call
else
  jd = JSON.parse json_data
  path     = './public' + Event#{event_id}::Generate#{name.split('_').map(&:capitalize).join}.new(attendee, jd).call
end
filename = File.basename(path)

AttendeeMailer.email_ce_certificate(attendee.notes_email, Event.find(attendee.event_id), filename, subject_text, content, path:path).deliver if send_email?"
        }
        puts "SUCCESS: pdf email script created.".green
      else
        puts "WARN: pdf email script file already exists.".yellow
      end
    end
  end
end
