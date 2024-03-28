###########################################
#BCBS 2020 MYS Exhibitors integration
###########################################
require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

# 1. Make an api call to authorize (using /Authorize) (1 call)
def mys_authorize
  uri = URI('https://api.mapyourshow.com/mysRest/v2/authorize?showCode=BCBSNS2020')
  response = Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme == 'https', 
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth 'EventKaddy', ENV['BCBS2020_EXH_AUTH']
    response = http.request request # Net::HTTPResponse object
  end
  return JSON.parse(response.body)
end

# 2. Call /Exhibitors/Modified to collect list of exhibitors that have been modified in a given date range (1 call)
def get_modified_exhibitors(auth_code,from_date)
  puts "from_date_2:#{from_date}"
  fromDate = URI.encode(from_date)
  puts "from_date_3:#{fromDate}"
  toDate = DateTime.now.strftime("%Y-%m-%d %H:%M")
  toDate = URI.encode(toDate)
  puts "to_date_1:#{toDate}"
  uri = URI("https://api.mapyourshow.com/mysRest/v2/exhibitors/modified?FromDate=#{fromDate}&ToDate=#{toDate}")
  puts uri

  response = http = Net::HTTP.start(uri.host, uri.port,  :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    request = Net::HTTP::Get.new(uri)
    request["showCode"] = 'BCBSNS2020'
    request["Authorization"] = "Bearer #{auth_code}"
    response = http.request(request)
    response
  end
  puts "to_date_2: #{toDate}"
  puts [response.read_body, toDate]
  [response.read_body, toDate]
end

# 3. For modified exhibitors, call /Exhibitors to get basic exhibitor data (up to 380 calls) 
def return_exhibitor_tags(exhibitor)
   # "productcategories":[{"parentcategoryid":0,"toplevelparent":0,"categoryid":7,"categoryname":"Development & Innovation","categorydisplay":"Development & Innovation"}]"
   tagset = []
   tag = exhibitor["productcategories"].blank? ? "" : exhibitor["productcategories"][0]["categorydisplay"]
   tagset << [tag]
  return [tagset, tag]
end

def return_exhibitor_attributes_hash(exhibitor,event_id, to_date, tag)
  puts "to_date:#{to_date}"
  #get exhibitors from last call, minus 1 day
  new_from_date = Date.parse(to_date) - 1 
  #  unused_fields = "package":"","sortkey":"","alpha":"T","address3":"","phone2":"","phone3":"","fax":"","fax2":"","dateadded":"January, 07 2020, 14:43:11","newexhibitor":"","twitter":"","linkedin":"","facebook":"","logo":"", 
  # "contacts":[{"zip":"","phone":"","state":"","city":"","country":"",,"phone2":"","address1":"","fax":"","address3":"","address2":""}] #also lname and fname separately, but we are using fullname

  # isactive??? - published?
  # approvestatus - published?

  #custom fields
  # booth_promotion_topic = exhibitor["booth_promotion_topic"]
  # business_area         = exhibitor["business_area"]
  # sponsorship           = exhibitor["sponsorship"]
  # license_owned         = exhibitor["license_owned"]
  # national_partner      = exhibitor["national_partner"]
  # subcategories         = "#{unique_subtags.sub(/(.*),\s/, '\1')}"
  # puts "subcats: #{subcategories}"

  #create json mapping for custom fields
  puts "exhibitor: #{exhibitor["exhname"]}, #{exhibitor["exhid"]}"
  custom_fields = [{}]
  # custom_fields[0]["title"] = "booth_promotion_topic"
  # custom_fields[0]["value"] = booth_promotion_topic
  # custom_fields[1]["title"] = "business_area"
  # custom_fields[1]["value"] = business_area
  # custom_fields[2]["title"] = "sponsorship"
  # custom_fields[2]["value"] = sponsorship
  # custom_fields[3]["title"] = "licensee-owned"
  # custom_fields[3]["value"] = license_owned
  # custom_fields[4]["title"] = "national_partner"
  # custom_fields[4]["value"] = national_partner
  # custom_fields[5]["title"] = "Sub-Categories"
  # custom_fields[5]["value"] = subcategories
  custom_fields[0]["from_date"] = new_from_date
  contact = exhibitor["contacts"][0]

  {
   event_id:       event_id,
   exhibitor_code: exhibitor["exhid"],
   company_name:   exhibitor["exhname"],
   description:    sanitize_for_db( exhibitor["description"] || ""),
   address_line1:  exhibitor["address1"],
   address_line2:  exhibitor["address2"],
   state:          exhibitor["state"],
   city:           exhibitor["city"],
   country:        exhibitor["country"],
   zip:            exhibitor["zip"],
   phone:          exhibitor["phone"],
   email:          exhibitor["contact_email"],
   url_web:        exhibitor["website"],
   message:        exhibitor["message"],
   contact_name:   contact["fullname"],
   email:          contact["email"],
   contact_title:  contact["title"],
   custom_fields:  custom_fields.to_json,
   tags_safeguard: tag.strip()
   # is_sponsor:     is_sponsor
  }
end

def update_location_mapping(event_id, exhibitor, location_mapping_type_id, ar_exhibitor)
  # {"hallid":"A","dimensions":"10 x 10","boothnumber":"1043","boothtype":"P","hall":"Exhibit Hall","squareft":100.0,"pavilion":"","boothtypedisplay":"10 x 10 Linear Booth"}
  booth_number = exhibitor["booths"].blank? ? "" : exhibitor["booths"][0]["boothnumber"]
  location_mapping = LocationMapping.where(name:booth_number,event_id:event_id).first_or_initialize
  location_mapping.update!(event_id:event_id,name:booth_number,mapping_type:location_mapping_type_id)
  ar_exhibitor.location_mapping = location_mapping
  ar_exhibitor.save
end

def update_or_create_exhibitor(exhibitor_attrs)
  exhibitor = Exhibitor.where(exhibitor_code:exhibitor_attrs[:exhibitor_code], event_id:exhibitor_attrs[:event_id]).first_or_initialize
  exhibitor.update!(exhibitor_attrs)
  exhibitor
end

def get_exhibitor_data(auth_code, exhibitor_id, event_id)
  uri = URI("https://api.mapyourshow.com/mysRest/v2/exhibitors?exhID=#{exhibitor_id}")
  response = Net::HTTP.start(uri.host, uri.port,  :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{auth_code}"
    response = http.request(request)
    return response.read_body
  end
  return response.read_body
end

# 4. For modified exhibitors, call /Contacts to get updated contact information (up to 380 calls) (Question: Will the /Exhibitors/Modified call return an exhibitor if only the contact data has been modified?) 
# 5. Call /Exhibitors/Categories/Modified to get list of exhibitors with modified categories (1 call)
# 6. For these exhibitors, call /Exhibitors/Categories to get modified categories (up to 380 calls)
# 7. Call /Booths/Assignments/Modified to get modified booth information (1 call)
ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

location_mapping_type_id = LocationMappingType.where(type_name:'Booth').pluck(:id).first
tag_type_id              = TagType.where(name:'exhibitor').pluck(:id).first


event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'MYS API', row:0, status:'In Progress')
end

job.start {

  job.status  = 'Fetching data from API'
  job.write_to_file
  response = mys_authorize
  auth_code = response[0]["mysGUID"]
  exhibitor = Exhibitor.where(event_id:event_id).order(custom_fields: :desc).first
  #Get the date the method was last called
  if !exhibitor.blank?
    custom_fields = JSON.parse(exhibitor.exhibitor_files_url)
    from_date = custom_fields[0]["from_date"].blank? ? "2019-01-01 00:00" : custom_fields[0]["from_date"]
    puts "from_date: #{from_date}"
  else
    from_date = "2019-01-01 00:00"
  end

  exhibitors, to_date = get_modified_exhibitors(auth_code,from_date)
  puts "to_date: #{to_date}"
  exhibitors = JSON.parse(exhibitors)
  exhibitors = exhibitors[0]["exhibitors"]
  job.update!(total_rows:exhibitors.length, status:'Processing Rows')
  job.write_to_file
  
  unless exhibitors.blank?
    exhibitors.each do |e|
      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

      exhibitor_id = e["exhid"]
      response = get_exhibitor_data(auth_code, exhibitor_id, event_id)
      response = JSON.parse(response)
      exhibitor = response[0]["exhibitor"]
      tagset, tag = return_exhibitor_tags(exhibitor)
      puts "to_date: #{to_date}"
      exhibitor_attributes = return_exhibitor_attributes_hash(exhibitor,event_id, to_date, tag)
      ar_exhibitor = update_or_create_exhibitor(exhibitor_attributes)
      update_location_mapping(event_id, exhibitor, location_mapping_type_id, ar_exhibitor)
      ar_exhibitor.update_tags tagset, 'exhibitor'
    end
  end

  job.status  = 'Cleanup'
  job.write_to_file

  Exhibitor.where(event_id:event_id).each do |e|
    verifyExhibitorTags(e.tags_safeguard, tag_type_id, event_id, e.company_name) if e.tags_safeguard!=nil
  end
}

# Questions
# I am populating exhibitor details in the exhibitors table. Do I also need to add the exhibitor to the attendees table (we didn't last year... )
# isactive??? - published?
# approvestatus - published?








