###########################################
# Custom Adjustment Script
# Update the track_subtrack field in the
# session table
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]

Session.where(event_id:EVENT_ID).each do |session|

	puts "updating session: #{session.session_code}"

	tagType = TagType.where(name:"session")[0]

	#find all the existing tag groups
	tags_session = TagsSession.select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').joins('
		JOIN tags ON tags_sessions.tag_id=tags.id'
		).where('session_id=? AND tags.tag_type_id=?',session.id,tagType.id)

	tag_groups = []
	tags_session.each_with_index do |tag_session,i|

		tag_groups[i] = []

		#add leaf tag
		tag_groups[i] << tag_session.tag_name
		parent_id = tag_session.tag_parent_id #acquired from above table join

		#add ancestor tags, if any
		while parent_id != 0
			tag = Tag.where(id:parent_id)
			if tag.length == 1
				tag_groups[i] << tag[0].name
				parent_id = tag[0].parent_id
			else
				parent_id = 0
			end
		end
		tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
	end
	track_subtrack = tag_groups[0].join ':' if tag_groups[0]
	puts track_subtrack

	session.update_attribute :track_subtrack, track_subtrack
end
