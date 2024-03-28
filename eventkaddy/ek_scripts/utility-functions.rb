# -*- coding: utf-8 -*-
#from PHP land
def addslashes(str)
  str.gsub(/['"\\\x0]/,'\\\\\0')
end

def sanitize_for_db(string_to_sanitize)
  string_to_sanitize.
    gsub(/\\n/,'<br>').
    gsub(/\\t/,'').
    gsub(/’/,"'").
    gsub(/”/,"'").
    gsub(/“/,"'").
    gsub(/\xe2\x80\x8e/, ' ').
    gsub(/\xEF\xAC\x81/, 'i').
    gsub(/\xE2\x80\x8B/, '')
end

#true/false on whether input is a number
def is_number(num)
    true if Float(num) rescue false
end

#utility function to auto-retry url
def apiFetch(url)

   retries = 10

   begin
     Timeout::timeout(150){
       open(url) do |f|
       	return f.read
       end
     }
   rescue Timeout::Error
     retries -= 1
     if (retries >= 0) then
     	 puts "open uri request fail, sleep 4 sec, retry #{10-retries} of 10"
       sleep 4 and retry
     else
       raise
     end

 		rescue
    	puts "Connection failed: #{$!}\n"

  	end

end

#new version using active record, based on version in utility-functions-old.rb
#set custom filters for apps that require custom session filtering
def addSessionTagsV2WithCustomFilters(event_id,tag_array,tag_type_id,session_code,c1,c2,c3)

	puts "Custom Filters: #{c1} #{c2} #{c3}"
	#return true

	#loop through all the sets of tags
	puts "tag_array: #{tag_array} , tag_type : #{tag_type_id}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

		parent_ids = [] #store all the parent ids for a tagset

		tagset.each_with_index do |tag,i|

			#set parent_id
			if (i > 0) then #child tag

				#get the parent_id of the current tag, add to parent_ids
				rows = Tag.where(name:tagset[i-1],parent_id:parent_ids[i-1], event_id:event_id,tag_type_id:tag_type_id,level:i-1).order('id DESC')
				parent_ids << rows.first['id']

				rows = Tag.where(name:tag,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id)
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id,custom_filter_1:c1,custom_filter_2:c2,custom_filter_3:c3}).save()
				elsif (rows.count == 1)
					puts "**-- NOT CREATING child tag: #{tag} --**\n"
					rows[0].update!(custom_filter_1:c1,custom_filter_2:c2,custom_filter_3:c3)
				end


			else #root-level tag

				rows = Tag.where(name:tag,event_id:event_id,tag_type_id:tag_type_id,level:0)
				parent_ids << 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[0],event_id:event_id,tag_type_id:tag_type_id,custom_filter_1:c1,custom_filter_2:c2,custom_filter_3:c3}).save()
				elsif (rows.count == 1)
					rows[0].update!(custom_filter_1:c1,custom_filter_2:c2,custom_filter_3:c3)
				end

			end



		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			parent_id = parent_ids.last

			puts "parent_id: #{parent_id}"

			#set leaf value to true
			updatetag = Tag.where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)[0].update!({leaf:1})

			sessionrow = Session.select('id').where(session_code:session_code,event_id:event_id)

			tagrow = Tag.select('id').where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)

			puts "session id: #{sessionrow.first.id} | tag id: #{tagrow.first.id}"

			rows = TagsSession.select('id').where(session_id:sessionrow.first['id'],tag_id:tagrow.first['id'])

			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and session #{sessionrow.first['id']} --\n"
				result = TagsSession.new({tag_id:tagrow.first['id'],session_id:sessionrow.first['id']}).save()
			end
		end

	end #tag_array.each do |tagset|

end

def add_tags_for_all_sessions(array_of_tag_arrays_and_session_codes, event_id, tag_type_id)

	array_of_tag_arrays_and_session_codes.each do |h|
		addSessionTagsV2(event_id, h[:session_tags], tag_type_id, h[:session_code])
	end
end

def get_array_of_session_codes_and_their_tags(event_id)

  array = []

  sessions = Session.where(event_id:event_id)

  tag_type_id = TagType.where(name:"session").first.id

  sessions.each do |session|
    #find all the existing tag groups
    tags_session = TagsSession.select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').joins('
      JOIN tags ON tags_sessions.tag_id=tags.id'
      ).where('session_id=? AND tags.tag_type_id=?', session.id, tag_type_id)

    tag_groups = []

    tags_session.each_with_index do |tag_session, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:event_id,id:parent_id)
        if (tag.length==1) then
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id = 0
        end
      end
      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end

    array << {:session_code => session.session_code, :session_tags => tag_groups}

  end

  return array

end

#new version using active record, based on version in utility-functions-old.rb
def addAttendeeTags(event_id, tag_array, tag_type_id, attendee_code)

	def child_tag?(i)
		i > 0
	end

	def return_parent_id(event_id, tag_type_id, tagset, parent_ids, i)
		Tag.where(name:tagset[i-1], parent_id:parent_ids[i-1], event_id:event_id,tag_type_id:tag_type_id,level:i-1).order('id DESC').pluck(:id).first
	end

	def child_tag_exists?(tag, parent_ids, event_id, tag_type_id, i)
		tags = Tag.where(name:tag,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id).pluck(:id); !(tags.length==0);
	end

	def tag_exists?(tag, event_id, tag_type_id)
		tags = Tag.where(name:tag,event_id:event_id,tag_type_id:tag_type_id,level:0).pluck(:id); !(tags.length==0);
	end

	def tags_attendee_exists?(attendee_row_id, tagrow_id)
		tags_attendees = TagsAttendee.where(attendee_id:attendee_row_id, tag_id:tagrow_id).pluck(:id); !(tags_attendees.length==0);
	end

	def set_last_tag_to_leaf(tagset, last_parent_id, event_id, tag_type_id)
		Tag.where(name:tagset.last, parent_id:last_parent_id, event_id:event_id, tag_type_id:tag_type_id).first.update!(leaf:1)
	end

	def create_tags_and_return_last_parent_id(tagset, event_id, tag_type_id)

		parent_ids = []

		tagset.each_with_index do |tag, i|

			if child_tag? i

				parent_ids << return_parent_id(event_id, tag_type_id, tagset, parent_ids, i)
				unless child_tag_exists?(tag, parent_ids, event_id, tag_type_id, i)
					puts "-- creating new child tag: #{tag} --\n"
					Tag.create(name:tag, level:i, leaf:0, parent_id:parent_ids[i], event_id:event_id, tag_type_id:tag_type_id)
				else
					puts "**-- NOT CREATING child tag: #{tag} --**\n"
				end
			else

				parent_ids << 0
				unless tag_exists?(tag, event_id, tag_type_id)
					puts "-- creating new root tag: #{tag} --\n"
					Tag.create(name:tag, level:i, leaf:0, parent_id:parent_ids[0], event_id:event_id, tag_type_id:tag_type_id)
				end
			end
		end
		parent_ids.last
	end

	def create_attendee_tag_association(last_parent_id, tagset, event_id, tag_type_id, attendee_code)
			puts "parent_id: #{last_parent_id}"
			set_last_tag_to_leaf(tagset, last_parent_id, event_id, tag_type_id)

			attendee_row_id = Attendee.where(account_code:attendee_code, event_id:event_id).pluck(:id).first
			tagrow_id       = Tag.where(name:tagset.last, parent_id:last_parent_id, event_id:event_id, tag_type_id:tag_type_id).pluck(:id).first

			puts "attendee id: #{attendee_row_id} | tag id: #{tagrow_id}"

			unless tags_attendee_exists?(attendee_row_id, tagrow_id)
				puts "\t\t-- creating relationship between tag #{tagrow_id} and attendee #{attendee_row_id} --\n"
				TagsAttendee.create(tag_id:tagrow_id, attendee_id:attendee_row_id)
			end
	end

	puts "tag_array: #{tag_array}, tag_type : #{tag_type_id}"

	tag_array.each do |tagset|

		puts "tagset: #{tagset}"
		last_parent_id = create_tags_and_return_last_parent_id(tagset, event_id, tag_type_id)

		create_attendee_tag_association(last_parent_id, tagset, event_id, tag_type_id, attendee_code) if tagset.length > 0
	end
end

#new version using active record, based on version in utility-functions-old.rb
def addSessionTagsV2(event_id,tag_array,tag_type_id,session_code)

	#loop through all the sets of tags
	puts "tag_array: #{tag_array} , tag_type : #{tag_type_id}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

		parent_ids = [] #store all the parent ids for a tagset

		tagset.each_with_index do |tag,i|

			#set parent_id
			if (i > 0) then #child tag

				#get the parent_id of the current tag, add to parent_ids
				rows = Tag.where(name:tagset[i-1],parent_id:parent_ids[i-1], event_id:event_id,tag_type_id:tag_type_id,level:i-1).order('id DESC')
				parent_ids << rows.first['id']

				rows = Tag.where(name:tag,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id)
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id}).save()
				else
					puts "**-- NOT CREATING child tag: #{tag} --**\n"
				end


			else #root-level tag

				rows = Tag.where(name:tag,event_id:event_id,tag_type_id:tag_type_id,level:0)
				parent_ids << 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[0],event_id:event_id,tag_type_id:tag_type_id}).save()
					end

			end

		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			parent_id = parent_ids.last

			puts "parent_id: #{parent_id}"

			#set leaf value to true
			updatetag = Tag.where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)[0].update!({leaf:1})

			sessionrow = Session.select('id').where(session_code:session_code,event_id:event_id)

			tagrow = Tag.select('id').where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)

			puts "session id: #{sessionrow.first.id} | tag id: #{tagrow.first.id}"

			rows = TagsSession.select('id').where(session_id:sessionrow.first['id'],tag_id:tagrow.first['id'])

			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and session #{sessionrow.first['id']} --\n"
				result = TagsSession.new({tag_id:tagrow.first['id'],session_id:sessionrow.first['id']}).save()
			end
		end

	end #tag_array.each do |tagset|

end



#add tags and their respective associations
def addSessionTags(dbh,event_id,tag_array,tag_type_id,session_code)

	#puts "session code top: #{session_code}"

	t = Time.now
	sql_tags = "INSERT INTO tags (id,name,level,leaf,parent_id,event_id,tag_type_id,created_at,updated_at ) VALUES "
	sql_tags_sessions = "INSERT INTO tags_sessions (id,tag_id,session_id,created_at,updated_at) VALUES "

	#loop through all the sets of tags
	puts "tag_array: #{tag_array} , tag_type : #{tag_type_id}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

			##EG-leaftag-FIX
			if dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first!=nil
				if dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first['leaf']===0 then
					puts "*********Tag set cannot end in tag category.*********"
					next
				end
			end

		#series_id = (0…50).map{ ('a'..'z').to_a[rand(26)] }.join
		tagset.each_with_index do |tag,i|
			#tag = tag.strip!

			#set parent_id
			if (i > 0) then #child tag
				rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[i-1]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND  level=\"#{i - 1}\" ORDER BY id DESC;")
				parent_id = rows.first['id']

				rows=dbh.query("SELECT id,name,parent_id FROM `tags` WHERE name=\"#{tag}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')") #(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
					end

			else #root-level tag

				rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tag}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND
				level=0;")
				parent_id = 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')") #(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
					end

			end

		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			#create session-tag association if needed
			rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[-2]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND level=\"#{tagset.length() - 2}\" ORDER BY id DESC;") #problem: doesn't handle identical parent and child names

			if (rows.count > 0) then
				parent_id = rows.first['id']
			else
				parent_id = 0
			end

			puts "parent_id: #{parent_id}"


			# puts "********************** #{dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first['leaf']} ***********************************"

			#set leaf value to true
			updatetag=dbh.query("UPDATE tags SET leaf='1' WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")

			sessionrow=dbh.query("SELECT id FROM `sessions` WHERE session_code=\"#{session_code}\" AND event_id=\"#{event_id}\";")
			tagrow=dbh.query("SELECT id FROM tags WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
			puts "session id: #{sessionrow.first} | tag id: #{tagrow.first}"
			rows=dbh.query("SELECT id FROM `tags_sessions` WHERE session_id=\"#{sessionrow.first['id']}\" AND tag_id=\"#{tagrow.first['id']}\"")
			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and session #{sessionrow.first['id']} --\n"
					dbh.query(sql_tags_sessions + "('','#{tagrow.first['id']}','#{sessionrow.first['id']}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")  	#(id,tag_id,session_id,created_at,updated_at)
			end
		end

	end #tag_array.each do |tagset|

end

def add_tags_for_all_exhibitors(array_of_tag_arrays_and_company_names, event_id, tag_type_id)

	array_of_tag_arrays_and_company_names.each do |h|
		addExhibitorTagsV2(event_id, h[:exhibitor_tags], tag_type_id, h[:company_name])
	end
end

def get_array_of_company_names_and_their_tags(event_id)

  array = []

  exhibitors = Exhibitor.where(event_id:event_id)

  exhibitors.each do |exhibitor|

			tag_type_id = TagType.exhibitor_type_id

			#find all the existing tag groups
			tags_exhibitor = TagsExhibitor.select('exhibitor_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').joins('
				JOIN tags ON tags_exhibitors.tag_id=tags.id'
				).where('exhibitor_id=? AND tags.tag_type_id=?',exhibitor.id,tag_type_id)

			tag_groups = []

			tags_exhibitor.each_with_index do |tag_exhibitor, i|

				tag_groups[i] = []

				#add leaf tag
				tag_groups[i] << tag_exhibitor.tag_name
				parent_id = tag_exhibitor.tag_parent_id #acquired from above table join

				#add ancestor tags, if any
				while (parent_id!=0)

					tag = Tag.where(event_id:event_id,id:parent_id)

					if (tag.length==1) then
						tag_groups[i] << tag[0].name
						parent_id     = tag[0].parent_id
					else
						parent_id = 0
					end
				end

				tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
			end

    array << {:company_name => exhibitor.company_name, :exhibitor_tags => tag_groups}
  end

  return array
end

#
#new version using active record, based on version in utility-functions-old.rb
def addExhibitorTagsV2(event_id, tag_array, tag_type_id, company_name)

	#t = Time.now
	# sql_tags = "INSERT INTO tags (id,name,level,leaf,parent_id,event_id,tag_type_id,created_at,updated_at ) VALUES "
	# sql_tags_sessions = "INSERT INTO tags_sessions (id,tag_id,session_id,created_at,updated_at) VALUES "

	#loop through all the sets of tags
	puts "tag_array: #{tag_array} , tag_type : #{tag_type_id}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

		#series_id = (0…50).map{ ('a'..'z').to_a[rand(26)] }.join
		tagset.each_with_index do |tag,i|
			#tag = tag.strip!

			#set parent_id
			if (i > 0) then #child tag
				#rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[i-1]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND  level=\"#{i - 1}\" ORDER BY id DESC;")
				rows = Tag.where(name:tagset[i-1],event_id:event_id,tag_type_id:tag_type_id,level:i-1).order('id DESC')
				parent_id = rows.first['id']


				#rows=dbh.query("SELECT id,name,parent_id FROM `tags` WHERE name=\"#{tag}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
				rows = Tag.where(name:tag,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						#dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
						 #(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id}).save()
					end

			else #root-level tag

				#rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tag}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND
				#level=0;")
				rows = Tag.where(name:tag,event_id:event_id,tag_type_id:tag_type_id,level:0)
				parent_id = 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						#dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
						#(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id}).save()
					end

			end

		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			#create session-tag association if needed
			#rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[-2]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND level=\"#{tagset.length() - 2}\" ORDER BY id DESC;") #problem: doesn't handle identical parent and child names
			rows = Tag.where(name:tagset[-2],event_id:event_id,tag_type_id:tag_type_id,level:tagset.length() - 2).order('id DESC')


			if (rows.count > 0) then
				parent_id = rows.first['id']
			else
				parent_id = 0
			end

			puts "parent_id: #{parent_id}"

			#set leaf value to true
			#updatetag=dbh.query("UPDATE tags SET leaf='1' WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
			updatetag = Tag.where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)[0].update!({leaf:1})

			exhibitorrow = Exhibitor.select('id').where(company_name:company_name,event_id:event_id)

			#tagrow=dbh.query("SELECT id FROM tags WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
			tagrow = Tag.select('id').where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)

			puts "exhibitor id: #{exhibitorrow.first} | tag id: #{tagrow.first}"

			rows = TagsExhibitor.select('id').where(exhibitor_id:exhibitorrow.first['id'],tag_id:tagrow.first['id'])

			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and exhibitor #{exhibitorrow.first['id']} --\n"
				result = TagsExhibitor.new({tag_id:tagrow.first['id'],exhibitor_id:exhibitorrow.first['id']}).save()
			end
		end

	end #tag_array.each do |tagset|

	#return true

end


#new version using active record, based on version in utility-functions-old.rb
def addExhibitorTagsV2(event_id,tag_array,tag_type_id,company_name)

	#loop through all the sets of tags
	puts "tag_array: #{tag_array} , tag_type : #{tag_type_id}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

		parent_ids = [] #store all the parent ids for a tagset

		tagset.each_with_index do |tag,i|

			#set parent_id
			if (i > 0) then #child tag

				#get the parent_id of the current tag, add to parent_ids
				rows = Tag.where(name:tagset[i-1],parent_id:parent_ids[i-1], event_id:event_id,tag_type_id:tag_type_id,level:i-1).order('id DESC')
				parent_ids << rows.first['id']

				rows = Tag.where(name:tag,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id)
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[i],event_id:event_id,tag_type_id:tag_type_id}).save()
				else
					puts "**-- NOT CREATING child tag: #{tag} --**\n"
				end


			else #root-level tag

				rows = Tag.where(name:tag,event_id:event_id,tag_type_id:tag_type_id,level:0)
				parent_ids << 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						result = Tag.new({name:tag,level:i,leaf:0,parent_id:parent_ids[0],event_id:event_id,tag_type_id:tag_type_id}).save()
					end

			end

		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			parent_id = parent_ids.last

			puts "parent_id: #{parent_id}"

			#set leaf value to true
			updatetag = Tag.where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)[0].update!({leaf:1})

			exhibitorrow = Exhibitor.select('id').where(company_name:company_name,event_id:event_id)

			tagrow = Tag.select('id').where(name:tagset.last,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)

			puts "exhibitor id: #{exhibitorrow.first.id} | tag id: #{tagrow.first.id}"

			rows = TagsExhibitor.select('id').where(exhibitor_id:exhibitorrow.first['id'],tag_id:tagrow.first['id'])

			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and exhibitor #{exhibitorrow.first['id']} --\n"
				result = TagsExhibitor.new({tag_id:tagrow.first['id'],exhibitor_id:exhibitorrow.first['id']}).save()
			end
		end

	end #tag_array.each do |tagset|

end


#add tags and their respective associations
def addExhibitorTags(dbh,event_id,tag_array,tag_type_id,company_name)

	t = Time.now
	sql_tags = "INSERT INTO tags (id,name,level,leaf,parent_id,event_id,tag_type_id,created_at,updated_at ) VALUES "
	sql_tags_exhibitors = "INSERT INTO tags_exhibitors (id,tag_id,exhibitor_id,created_at,updated_at) VALUES "

	#loop through all the sets of tags
	puts "tag_array: #{tag_array}"
	tag_array.each do |tagset|
		puts "tagset: #{tagset}"

		##EG-leaftag-FIX
		if dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first!=nil
			if dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first['leaf']===0 then
				puts "*********Tag set cannot end in tag category.*********"
				next
			end
		end

		#series_id = (0…50).map{ ('a'..'z').to_a[rand(26)] }.join
		tagset.each_with_index do |tag,i|
			#tag = tag.strip!

			#set parent_id
			if (i > 0) then #child tag
				rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[i-1]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND  level=\"#{i - 1}\" ORDER BY id DESC;")
				parent_id = rows.first['id']

				rows=dbh.query("SELECT id,name,parent_id FROM `tags` WHERE name=\"#{tag}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
				if (rows.count == 0) then
					puts "-- creating new child tag: #{tag} --\n"
						dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')") #(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
					end

			else #root-level tag

				rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tag}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND
				level=0;")
				parent_id = 0

				if (rows.count == 0) then
					puts "-- creating new root tag: #{tag} --\n"
						dbh.query(sql_tags + "('','#{tag}',#{i},'0','#{parent_id}','#{event_id}','#{tag_type_id}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')") #(id,name,level,leaf,parent_id,event_id,created_at,updated_at )
					end


			end

		end #tagset.each_with_index do |tag,i|


		if ( tagset.length > 0 ) then

			#create exhibitor-tag association if needed
			rows=dbh.query("SELECT id FROM `tags` WHERE name=\"#{tagset[-2]}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\" AND level=\"#{tagset.length() - 2}\" ORDER BY id DESC;") #problem: doesn't handle identical parent and child names

			if (rows.count > 0) then
				parent_id = rows.first['id']
			else
				parent_id = 0
			end

			puts "parent_id: #{parent_id}"

			##EG-leaftag-FIX
			if dbh.query("SELECT leaf FROM tags WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";").first===false then
				raise "Tag set cannot end in tag category."
			end

			#set leaf value to true
			updatetag=dbh.query("UPDATE tags SET leaf='1' WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")

			exhibitorrow=dbh.query("SELECT id FROM `exhibitors` WHERE company_name=\"#{company_name}\" AND event_id=\"#{event_id}\"")

			tagrow=dbh.query("SELECT id FROM tags WHERE name=\"#{tagset.last}\" AND parent_id=\"#{parent_id}\" AND event_id=\"#{event_id}\" AND tag_type_id=\"#{tag_type_id}\";")
			puts "exhibitor id: #{exhibitorrow.first} | tag id: #{tagrow.first}"
			rows=dbh.query("SELECT id FROM `tags_exhibitors` WHERE exhibitor_id=\"#{exhibitorrow.first['id']}\" AND tag_id=\"#{tagrow.first['id']}\"")
			if (rows.count==0) then
				puts "\t\t-- creating relationship between tag #{tagrow.first['id']} and exhibitor #{exhibitorrow.first['id']} --\n"
					dbh.query(sql_tags_exhibitors + "('','#{tagrow.first['id']}','#{exhibitorrow.first['id']}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")  	#(id,tag_id,exhibitor_id,created_at,updated_at)
			end
		end

	end #tag_array.each do |tagset|

end

# dont use commas and colons, since clients always want those in tags.
def verifySessionTagsV2(tagset,tag_type_id,event_id,session_code)

	session_id = Session.where(event_id:event_id,session_code:session_code).first.id

	tags = tagset.split('^^').map { |a| a.strip }
	tags.each_with_index do |item,i|
		tags[i] = addslashes(item).split('||').map { |a| a.strip }
	end

	tags.each do |tagset|

		result = ''
		link_text = ''
		parent_id = 0
		tagset.each_with_index do |tag,i|

			if (i==0) then
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += "#{tag}".green
					parent_id = tag_result.first['id']
				else
					result += "MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsSession.where(session_id:session_id,tag_id:tag_result.first['id'])
					if (link_result.length == 1) then
						link_text = "session/tag link verified".green
					else
						link_text = "SESSION/TAG LINK MISSING".red
					end
				end

			else
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += " --> #{tag}".green
					parent_id = tag_result.first['id']
				else
					result += " --> MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsSession.where(session_id:session_id,tag_id:tag_result.first['id'])
					if (link_result.length == 1) then
						link_text = "session/tag link verified".green
					else
						link_text = "SESSION/TAG LINK MISSING".red
					end
				end

			end
		end

		puts "#{session_code}  | #{result} |  #{link_text}"
	end

end

### verify session tagsets have been correctly inserted in the database ###
def verifySessionTags(tagset,tag_type_id,event_id,session_code)

	session_id = Session.where(event_id:event_id,session_code:session_code).first.id

	tags = tagset.split(',').map { |a| a.strip }
	tags.each_with_index do |item,i|
		tags[i] = addslashes(item).split(':').map { |a| a.strip }
	end

	tags.each do |tagset|

		result = ''
		link_text = ''
		parent_id = 0
		tagset.each_with_index do |tag,i|

			if (i==0) then
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += "#{tag}".green
					parent_id = tag_result.first['id']
				else
					result += "MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsSession.where(session_id:session_id,tag_id:tag_result.first['id'])
					if (link_result.length == 1) then
						link_text = "session/tag link verified".green
					else
						link_text = "SESSION/TAG LINK MISSING".red
					end
				end

			else
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += " --> #{tag}".green
					parent_id = tag_result.first['id']
				else
					result += " --> MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsSession.where(session_id:session_id,tag_id:tag_result.first['id'])
					if (link_result.length == 1) then
						link_text = "session/tag link verified".green
					else
						link_text = "SESSION/TAG LINK MISSING".red
					end
				end

			end
		end

		puts "#{session_code}  | #{result} |  #{link_text}"
	end

end

### verify exhibitor tagsets have been correctly inserted in the database ###
def verifyExhibitorTags(tagset,tag_type_id,event_id,company_name)

	exhibitor_id = Exhibitor.where(event_id:event_id,company_name:company_name).first.id

	tags = tagset.split(',').map { |a| a.strip }
	tags.each_with_index do |item,i|
		tags[i] = addslashes(item).split(':').map { |a| a.strip }
	end

	### verify the tagsets have been correctly inserted in the database ###
	tags.each do |tagset|

		result = ''
		link_text = ''
		parent_id = 0
		tagset.each_with_index do |tag,i|

			if (i==0) then
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += "#{tag}".green
					parent_id = tag_result.first['id']
				else
					result += "MISSING #{tag}".red
					next
				end

			else
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += " --> #{tag}".green
					parent_id = tag_result.first['id']
				else
					result += " --> MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsExhibitor.where(exhibitor_id:exhibitor_id,tag_id:tag_result.first['id'])
					if (link_result.length == 1) then
						link_text = "exhibitor/tag link verified".green
					else
						link_text = "EXHIBITOR/TAG LINK MISSING".red
					end
				end

			end
		end

		puts "#{company_name}  | #{result} |  #{link_text}"
	end

end

def verifyAttendeeTags(tagset, tag_type_id, event_id, account_code)
	# "BCBS Plan/Company||custom_filer_1||attendee_compamy^^Business Discipline||business_unit"
	attendee_id = Attendee.where(event_id:event_id,account_code:account_code).pluck(:id).first

	tags = tagset.split('^^').map { |a| a.strip }
	tags.each_with_index do |item,i|
		tags[i] = addslashes(item).split('||').map { |a| a.strip }
	end

	### verify the tagsets have been correctly inserted in the database ###
	tags.each do |tagset|
		# [["BCBS Plan/Company", "custom_filer_1", "attendee_compamy"], ["Business Discipline", "business_unit"]]
		result = ''
		link_text = ''
		parent_id = 0
		tagset.each_with_index do |tag,i|

			if i==0
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += "#{tag}".green
					parent_id = tag_result.first.id
				else
					result += "MISSING #{tag}".red
					next
				end

			else
				tag_result = Tag.where(name:tag,level:i,parent_id:parent_id,event_id:event_id,tag_type_id:tag_type_id)
				if (tag_result.length == 1) then
					result += " --> #{tag}".green
					parent_id = tag_result.first.id
				else
					result += " --> MISSING #{tag}".red
					next
				end

				#if it's a leaf, verify tag is linked to session
				if (tag_result.length == 1 && tag_result.first['leaf']==true) then
					link_result = TagsAttendee.where(attendee_id:attendee_id,tag_id:tag_result.first.id)
					if (link_result.length == 1) then
						link_text = "attendee/tag link verified".green
					else
						link_text = "ATTENDEE/TAG LINK MISSING".red
					end
				end

			end
		end

		puts "#{account_code}  | #{result} |  #{link_text}"
	end

end

def return_titleized_name(name)
  if name === name.upcase || name === name.downcase
    if name.length > 4
      name = name.titleize
    end
  end
  name
end
