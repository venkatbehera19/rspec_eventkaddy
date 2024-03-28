###########################################
# Custom Adjustment Script
# Regenerate AVMA 2016 Attendee Tags
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'
ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

EVENT_ID = 78 #AVMA 2016
JOB_ID   = ARGV[0]

def remove_attendee_tags_and_associations

	tags         = Tag.where(event_id:EVENT_ID, tag_type_id:4)
	leaf_tag_ids = tags.where(leaf:1).pluck(:id)
	associations = TagsAttendee.where(tag_id:leaf_tag_ids)

	# puts tags.pluck(:id).inspect.green
	# puts leaf_tag_ids.inspect.red

#	puts "#{tags.pluck(:id).length} tags to destroy"
#	puts "#{leaf_tag_ids.length} leaf tags to destroy"
#	puts "#{associations.length} associations to destroy"

	tags.destroy_all
	associations.destroy_all
end

def regenerate_attendee_tags attendee

  first_letter_of_last_name     = attendee.last_name[0].upcase
  employment_area_demo_question = attendee.custom_filter_2
  primary_species_category      = attendee.custom_filter_3
  tagsets                       = []

  tagsets << ['Location', attendee.country, attendee.state]                                    unless attendee.country.blank? || attendee.state.blank?
  tagsets << ['Primary Species Category', primary_species_category, first_letter_of_last_name] unless primary_species_category.blank?

 #puts "Generating tagsets: #{tagsets.inspect}"

  GenerateTagsForModel.new(attendee, tagsets, 'attendee').call
end

if JOB_ID
	job = Job.find JOB_ID
	job.update!(original_file:'EK Database', row:0, status:'In Progress')
  job.write_to_file
end

job.start {
  attendees = Attendee.where event_id:EVENT_ID
	job.update!(total_rows:attendees.length, status:'Removing data that will be regenerated')
  job.write_to_file

  remove_attendee_tags_and_associations
	job.update! status:'Processing Rows'
  job.write_to_file

	attendees.each do |attendee|
    job.row = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0
    regenerate_attendee_tags attendee
  end
}


