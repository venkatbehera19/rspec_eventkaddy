# spreadsheet gem
require 'roo'

class Import

  attr_accessor :possible_fields, :column_names, :spreadsheet_path,
    :spreadsheet, :row_number, :header_row_number

  def valueFor name, default=nil
    index = column_names[name]
    result = index && spreadsheet.cell(row_number, index + 1) || default
    # don't yield a block if the column didn't exist. if no block, always return something
    index && block_given? ? yield( result ) : result
  end

  def maybeIntValueToString name, default=nil
    # we often have a column like speaker_code which could be all numbers
    # or could be a combination of letters and numbers. In the case it's
    # all numbers, this guards against it getting converted to a float.
    # In any other case, we just get back the result or default if it's
    # falsey
    result = spreadsheet.cell row_number, column_names[name] + 1
    result = result.to_i.to_s if Import.is_number result
    result ? result : default
  end

  def numberValueFor name, default=nil
    result = spreadsheet.cell row_number, column_names[name] + 1
    Import.is_number( result ) ? result.to_i : default
  end

  def boolValueFor name, default=nil
    result = spreadsheet.cell row_number, column_names[name] + 1
    result = result.downcase if result.is_a? String
    if result == 'true' || result == 1 || result == '1' || result == 'yes'
      true
    elsif result == '' || result == nil
      default
    else
      false
    end
  end

  # def dateTimeValueFor name, default=nil
  #   # for date times, where we don't want ruby to convert the time for us
  #   result = spreadsheet.cell row_number, column_names[name] + 1
  #   puts result
  #   if result
  #     result = result.split(' ')
  #     ymd = result[0].split('-')
  #     hms = result[1].split(':')
  #     puts Time.new(*ymd, *hms, '+00:00')
  #     Time.new(*ymd, *hms, '+00:00')
  #   else
  #     default
  #   end
  # end


  def self.is_number num
    # this seems hacky; but it's an old trick from utility functions
    # that hasn't broke yet; Float will coerce a string containing
    # only digits or an Int to Float, but error otherwise.
    true if Float(num) rescue false
  end

  def initialize args
    @spreadsheet_path  = args[:spreadsheet_path]
    @spreadsheet       = Import.load_spreadsheet spreadsheet_path
    @possible_fields   = args[:possible_fields]
    @header_row_number = args[:header_row_number] || 1
    unless args.fetch(:skip_generate_column_names, false)
      @column_names      = Import.generate_column_names possible_fields, collect_field_names
    end
    @row_number        = 0
  end

  def reinitialize args
    @possible_fields   = args[:possible_fields]
    @header_row_number = args[:header_row_number] || 1
    @column_names      = Import.generate_column_names possible_fields, collect_field_names
  end

  def self.connect_to_database
    # top level instance variables usually from ek_scripts/settings.rb
    # kind of hacky way to access it, but since settings.rb is not in
    # the repository, prevents other devs from needing to change their
    # own settings.rb
    main = TOPLEVEL_BINDING.eval('self')
    ActiveRecord::Base.establish_connection(
      adapter: "mysql2",
      host:     main.instance_variable_get(:@db_host),
      username: main.instance_variable_get(:@db_user),
      password: main.instance_variable_get(:@db_pass),
      database: main.instance_variable_get(:@db_name))
  end

  def self.load_spreadsheet path
    case path
    when /.*\.xlsx$/
      Roo::Excelx.new path
    when /.*\.xls$/
      Roo::Excel.new path
    when /.*\.ods$/
      Roo::Openoffice.new path
    else
      raise "Spreadsheet format not supported."
    end
  end

  def collect_field_names
    Import.column_letters.map {|col| spreadsheet.cell(header_row_number, col) }.compact.map &:downcase
  end

  def self.column_letters
    ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']
  end

  def self.generate_column_names headers, actual_fields
    column_indexes = {}
    # don't mess up index of real actual fields
    actual_fields_copy = Array.new actual_fields
    headers.each do |possible_names|
      possible_names.each do |name|
        index = actual_fields.index(name)
        if index
          possible_names.each {|name| column_indexes[name] = index }
          actual_fields_copy.delete name
        end
      end
    end
    # leftover fields from excel sheet are not defined in this script
    if actual_fields_copy.length > 0
      raise "The following columns are incorrectly named: #{actual_fields_copy.inspect}".red
    end
    column_indexes
  end

  def step_through_rows args={}
    start  = args.fetch :start, header_row_number + 1
    finish = args.fetch :finish, spreadsheet.last_row
    sheet  = args.fetch :sheet, spreadsheet.sheets[0]
    spreadsheet.default_sheet = sheet
    start.upto(finish) { |rn| @row_number = rn; yield rn }
  end

end

