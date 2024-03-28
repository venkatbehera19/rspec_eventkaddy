jQuery ->

  $('#sessionsettings-tabs li').removeClass 'active'
  
  wh = window.location.pathname
  
  if wh.match "tabs/4/edit"
    $('#edit_headers_footers-tab').addClass("active")
  else if wh.match "event_settings/edit_session_notes_content"
    $('#edit_session_notes-tab').addClass("active")
  else if wh.match "event_settings/edit_av_requirements"
    $('#edit_av_requests-tab').addClass("active")