class DeltaReport

  attr_accessor :headers, :before, :after, :delta, :treat_nil_and_blank_string_same, :strip_strings_before_comparing, :ignore_linebreaks, :treat_falsey_values_equal, :types, :user_id

  # schema should be keys mapped to values that represent axlsx type, or just an array of headers
  # The safest type is probably :string, it's possible we would want to just default that
  # From Documentation:
  # If the value provided cannot be cast into the type specified, type 
  # is changed to :string and the following logic is applied. :string 
  # to :integer or :float, type conversions always return 0 or 0.0 
  # :string, :integer, or :float to :time conversions always return the
  # original value as a string and set the cells type to :string. No 
  # support is currently implemented for parsing time strings.
  def initialize schema, args={}
    # Sometimes number values display oddly, especially when relying on axlsx
    # to decide for you. In case you don't want to specify every type, this
    # option may be useful
    axlsx_force_string_type = args.fetch(:axlsx_force_string_type, false)
    if schema.is_a? Array
      @headers = schema
      @types = axlsx_force_string_type ? schema.map {|x| :string } : []
    else
      @headers = schema.keys
      # unsure whether I want force string type to override, could be convenient
      # in some circumstances, or could trick you in others
      @types = axlsx_force_string_type ? schema.map {|x| :string } : schema.values
    end

    @delta = []

    # options to reduce noise in output over inconsequential differences
    @treat_nil_and_blank_string_same = args.fetch(:treat_nil_and_blank_string_same, false)
    @treat_falsey_values_equal       = args.fetch(:treat_falsey_values_equal, false)
    @strip_strings_before_comparing  = args.fetch(:strip_strings_before_comparing, false)
    @ignore_linebreaks               = args.fetch(:ignore_linebreaks, false) # as in \n vs \r
    @user_id                         = args.fetch(:user_id, false)
  end

  def both_falsey? before, after
    ![before, after].any? {|v| v != nil && v != false}
  end

  def both_nil_or_blank? before, after
    ![before, after].any? {|v| v != nil && v != ''}
  end

  def same? before, after, key
    if strip_strings_before_comparing
      before[key] = before[key].strip if before[key].is_a? String
      after[key] = after[key].strip if after[key].is_a? String
    end
    if ignore_linebreaks
      before[key] = before[key].gsub(/[\r\n]/, "") if before[key].is_a? String
      after[key] = after[key].gsub(/[\r\n]/, "") if after[key].is_a? String
    end

    result = before[key] == after[key]

    if !result && treat_nil_and_blank_string_same
      result = both_nil_or_blank? before[key], after[key]
    end

    if !result && treat_falsey_values_equal
      result = both_falsey? before[key], after[key]
    end

    result
  end

  def difference
    diff = ->( before, after ) {
      (before.keys + after.keys).uniq.inject({}) do |changes, key|
        unless same? before, after, key
          # possibly unnecessary recursion that wouldn't work with our headers system
          if before[key].kind_of?(Hash) && after[key].kind_of?(Hash)
            changes[key] = diff[ before[key], after[key] ]
          else
            changes[key] = [before[key], after[key]] 
          end
        end
        changes
      end
    }
    diff[ before, after ]
  end

  def compare (status = {})
    result = difference
    delta << {before: before, after: after, change: result, db_status: status } unless result.blank? 
    delta << {before: before, after: nil, change: result, db_status: status } if (result.blank? && !status.blank? && status[:status].eql?('failed'))
  end

  def change_to_human_readable change
    change.map do |name, value|
      "#{name}: \"#{value[0]}\" TO \"#{value[1]}\""
    end.join(', ')
  end

  def row hash
    headers.map do |t|
      hash[ t ]
    end
  end

  def row_style_differences hash, changes, style
    headers.map do |t|
      # if hash[ t ]
        changes.keys.include?(t) ? style : 0
      # else
      #   false
      # end
    end
  end

  def export title, event_id
    path    = Rails.root.join('public', 'event_data', event_id.to_s, 'deltas', title)
    dirname = File.dirname( path )
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    p = Axlsx::Package.new
    wb = p.workbook
    wb.styles do |s|
      black_cell = s.add_style :bg_color => "00", :fg_color => "FF", :sz => 14, :alignment => { :horizontal=> :left }
      grey_cell = s.add_style :bg_color => "7F827A", :fg_color => "FF", :sz => 14, :alignment => { :horizontal=> :left }
      green_cell = s.add_style :bg_color => "C4F8CE", :fg_color => "00", :sz => 14, :alignment => { :horizontal=> :left }
      yellow_cell = s.add_style :bg_color => 'FAEB89'

      wb.add_worksheet(:name => "Basic Worksheet") do |sheet|

        if delta.length == 0
          sheet.add_row ["No changes were made; For brevity, some changes like removal or addition of trailing spaces are ignored."]
        else
          sheet.add_row headers.map(&:to_s).map(&:titleize), :style => headers.map {|s| black_cell }
          delta.each do |d|
            sheet.add_row row( d[:before] ), :style => row_style_differences( d[:before], d[:change], green_cell ), types: types
            sheet.add_row row( d[:after] ), :style => row_style_differences( d[:after], d[:change], green_cell ), types: types
            sheet.add_row ["Change Summary", change_to_human_readable(d[:change])], :style => [grey_cell]
            sheet.add_row([ 'Database Commit Status', "#{d[:db_status][:status].capitalize} #{"Notes:" if d[:db_status][:status].eql?('failed')} #{d[:db_status][:message]}" ], style: [grey_cell, d[:db_status][:status].eql?('failed') ? yellow_cell : nil]) unless d[:db_status].blank?
            sheet.add_row []
          end
        end
      end
    end
    p.use_shared_strings = true
    p.serialize( path ) && update_db_and_upload_to_s3(path, event_id, title, dirname)
    path
  end

  def update_db_and_upload_to_s3 full_path, event_id, filename, dirname
    event = Event.find(event_id)
    cloud_storage_type = CloudStorageType.find(event.cloud_storage_type_id)
    event_file_type = EventFileType.where(name: 'event_delta_reports').first_or_create
    event_file = EventFile.new(event_id: event_id,
      event_file_type_id: event_file_type.id,
      path: full_path.sub(Rails.root.join('public').to_path, ''),
      cloud_storage_type_id: event.cloud_storage_type_id,
      name: filename,
      size: File.size(full_path.to_path),
      mime_type: MIME::Types.type_for(full_path.to_path).first.content_type
    )
    event_file.save!
    UploadEventFile.new({
      event_file: event_file,
      file: File.open(full_path.to_path),
      target_path: dirname,
      new_filename: filename,
      cloud_storage_type: cloud_storage_type,
      content_type: event_file.mime_type
    }).call
    puts "------------ Delta Report saved to s3 ---------------------".red
    ChangeReport.create!(
      user_id: user_id,
      event_id: event_id,
      upload_action: filename.split('_delta').first,
      event_file_id: event_file.id,
      created_at: Time.parse( filename.split('_').last.gsub('.xlsx', '') )
    )
  end

end

# delta_report = DeltaReport.new [ :name, :occupation, :hobby ]

# delta_report.before = {name: 'code bear', occupation: "teddy bear", hobby: 'sitting'}
# delta_report.after = {name: 'code bear', occupation: "ceo of daveco", hobby: 'bossing'}
# delta_report.compare

# delta_report.before = {name: 'Ed', occupation: "professor of cuteology"}
# delta_report.after = {name: 'Ed', occupation: "professor of cuteology"}
# delta_report.compare

# delta_report.before = {name: 'Kuro Kuma', occupation: "bossing"}
# delta_report.after = {name: 'Kuro Kuma', occupation: "teddy bear"}
# delta_report.compare

# delta_report.delta
# delta_report.export 'delta_text.xlsx', 0
