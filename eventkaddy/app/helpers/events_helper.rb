module EventsHelper

  ## the buttons were refactored and moved to the scripts and script_types tables
  def config_page_extra_buttons
   
  end

  def added_user_tags(users, ids)
    added_users = users.where(id: ids)
    tags = ""
    added_users.each do |user|
      tags += "<span class='add-user-tags' id=#{user.id}>" + 
        user.email + 
        "<span class='remove-tag ml-2'>&times;</span>" +  
      "</span>"
    end
    tags.html_safe
  end

end
