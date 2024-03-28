jQuery ->
	
#  $('#speaker-tabs li').click (e) ->
#    $('#speaker-tabs li').removeClass 'active'
#    $(e.currentTarget).addClass 'active'

  $('#event-tabs li').removeClass 'active'
  
  wh = window.location.pathname
  
  if wh.match "edit_event_settings"
    $('#edit_event_settings-tab').addClass("active")
  else if wh.match "edit_event_tabs"
    $('#edit_event_tabs-tab').addClass("active")
  else if wh.match "edit_exhibitor_event_tabs"
    $('#edit_exhibitor_event_tabs-tab').addClass("active")
  else if wh.match "edit_exhibitor_welcome"
    $('#edit_exhibitor_welcome-tab').addClass("active")
  else if wh.match "edit_requirements"
    $('#edit_requirements-tab').addClass("active")