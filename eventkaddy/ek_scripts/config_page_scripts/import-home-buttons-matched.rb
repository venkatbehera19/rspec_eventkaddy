###########################################
# Ruby script to import home button data 
# from spreadsheet into EventKaddy CMS
###########################################

# this loads rails, active record, and the dev database
require_relative '../../config/environment.rb' 

# abtracted methods shared by xlsx imports
require_relative '../import.rb'

# these two lines allow you to change the database that was connected 
# to by loading environement.rb;
require_relative '../settings.rb'
Import.connect_to_database

EVENT_ID         = ARGV[0]
SPREADSHEET_PATH = ARGV[1]
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

# For Testing
# [HomeButton, CustomListItem, CustomList].map {|m| m.where(event_id:20).length }
# [HomeButton, CustomListItem, CustomList].each {|m| m.where(event_id:20).destroy_all}
# EVENT_ID         = 20
# SPREADSHEET_PATH = './ek_scripts/config_page_scripts/hb.xlsx'
# JOB_ID = Job.try_to_create_job(
#            name:     "my test",
#            event_id: EVENT_ID)[:job_id]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(
    original_file: SPREADSHEET_PATH,
    row:           0,
    status:        'In Progress')
end

job.start {

  event_file_type_id = EventFileType.where(name:"home_button_icon").first.id

  home_button_import = Import.new({
    spreadsheet_path: SPREADSHEET_PATH,
    skip_generate_column_names: true, # need to determine header_row after init
    possible_fields: [
      ['id'], ['position'], ['name'], ['enabled'],
      ['type'], ['external link'], ['survey id'], ['attendee type']
    ]
  })

  job.update!(
    total_rows: home_button_import.spreadsheet.last_row,
    status:     'Processing Rows')

  home_button_header_row_number = home_button_import.spreadsheet
  .column(1)
  .find_index 'Home Buttons'

  if home_button_header_row_number
    # add two; one to account for index, another to get to headers
    home_button_header_row_number += 2
    home_button_import.header_row_number = home_button_header_row_number
    home_button_import.column_names = Import.generate_column_names(
      home_button_import.possible_fields, home_button_import.collect_field_names
    )
  else
    raise "Could not find \"Home Buttons\" in Column A; Please try downloading your home buttons first to see the correct format."
  end

  
  custom_list_header_row_number = home_button_import.spreadsheet
    .column(1)
    .find_index 'Custom List Items'

  if custom_list_header_row_number
    # add two; one to account for index, another to get to headers
    custom_list_header_row_number += 2
  else
    raise "Could not find \"Custom List Items\" in Column A; Please try downloading your home buttons first to see the correct format."
  end

  finish = custom_list_header_row_number - 2 

  duplicate_positions = home_button_import
    .spreadsheet
    .column(home_button_import.column_names['position'] + 1) [home_button_import.header_row_number..(finish - 1)]
    .group_by{ |e| e }
    .select { |k, v| v.size > 1 }
    .map(&:first)

  if duplicate_positions.length > 0
    duplicate_positions.map! {|p| p.blank? ? 'BLANK_CELL' : p.to_i }
    raise "Home Button position(s) #{duplicate_positions.join(', ')} occured more than once."
  end

  home_button_import.step_through_rows(finish: finish) do |row_number|

    job.row = row_number
    job.write_to_file if job.row % job.rows_per_write == 0

    id = home_button_import.numberValueFor( 'id' )

    begin
      type_id = HomeButtonType
        .where(name: home_button_import.valueFor( 'type' ))
        .first.id
    rescue
      raise "Invalid type: #{home_button_import.valueFor( 'type' )}"
    end

    begin
      attendee_type_id = if home_button_import.valueFor( 'attendee type' ) == 'All'
                           nil
                         else
                           AttendeeType.
                             where(name: home_button_import.valueFor( 'attendee type' )).first.id
                         end
    rescue
      raise "Invalid type: #{home_button_import.valueFor( 'attendee type' )}"
    end

    home_button_attrs = {
      event_id:            EVENT_ID,
      name:                home_button_import.valueFor( 'name' ),
      position:            home_button_import.numberValueFor( 'position' ),
      enabled:             home_button_import.boolValueFor( 'enabled' ),
      home_button_type_id: type_id,
      external_link:       home_button_import.valueFor( 'external link' ),
      survey_id:           home_button_import.numberValueFor( 'survey id' ),
      attendee_type_id:    attendee_type_id
    }

    home_button = if id
                    home_button = HomeButton.find id
                    if home_button.event_id != EVENT_ID.to_i
                      raise "HomeButton id belonged to another event.  Please leave id blank to create new home buttons, or upload a spreadsheet you've downloaded and updated instead."
                    end
                    home_button
                  else
                    HomeButton.new
                  end

    unless home_button.event_file_id
      event_file = EventFile.create(
        event_id:           EVENT_ID,
        name:               'placeholder.png',
        mime_type:          "image/png",
        path:               "/event_data/#{EVENT_ID}/home_button_group_images/exhibitors.png",
        event_file_type_id: event_file_type_id)
      home_button.event_file_id    = event_file.id
      home_button.icon_button_name = 'placeholder.png'
    end

    unless home_button.update! home_button_attrs
      raise home_button.errors
    end

    if home_button.home_button_type.name==="Custom List"
      home_button.createAssociatedCustomListAndCustomListType 
    end
  end

  # Begin Processing Custom List Items Table

  home_button_import.reinitialize(
    possible_fields: [ 
      ["id"], ["home button id"], ["position"], ["title"], ["content"] 
    ],
    header_row_number: custom_list_header_row_number
  )

  duplicate_positions = []
  home_button_import.step_through_rows do |row_number|
    hb_id = home_button_import.numberValueFor( 'home button id' )
    next unless hb_id
    duplicate_positions << "Home Button Id: #{hb_id}, Position: #{home_button_import.numberValueFor( 'position' )}"
  end

  duplicate_positions = duplicate_positions.group_by{ |e| e }
    .select { |k, v| v.size > 1 }
    .map(&:first)

  if duplicate_positions.length > 0
    raise "Custom List Item position(s) #{duplicate_positions} occured more than once for the same Home Button ID."
  end

  home_button_import.step_through_rows do |row_number|

    job.row = row_number
    job.write_to_file if job.row % job.rows_per_write == 0

    id             = home_button_import.numberValueFor( 'id' )
    home_button_id = home_button_import.numberValueFor( 'home button id' )

    if home_button_id && 
       HomeButton.find(home_button_id).event_id != EVENT_ID.to_i
        raise "Home Button ID for Custom List Item belonged to another event. Please select one of the IDs from the first table to assign a custom list item to that home button (only effectual on Custom List type Home Buttons)."
    end

    unless home_button_id
      warning_msg = "Home Button ID not given for #{home_button_import.valueFor('title')}; skipping row."
      job.warnings = !job.warnings ? warning_msg : "#{job.warnings}||#{warning_msg}"
      job.write_to_file
      next
    end

    custom_list_item_attrs = {
      event_id:       EVENT_ID,
      position:       home_button_import.numberValueFor( 'position' ),
      title:          home_button_import.valueFor( 'title' ),
      content:        home_button_import.valueFor( 'content' ),
      custom_list_id: CustomList.where(home_button_id:home_button_id).first.id
    }

    custom_list_item = if id
                        custom_list_item = CustomListItem.find id
                        if custom_list_item.event_id != EVENT_ID.to_i
                          raise "CustomListItem id belonged to another event.  Please leave id blank to create new custom list items, or upload a spreadsheet you've downloaded and updated instead."
                        end
                        custom_list_item
                      else
                        CustomListItem.new
                      end
    custom_list_item.update! custom_list_item_attrs
  end
}

