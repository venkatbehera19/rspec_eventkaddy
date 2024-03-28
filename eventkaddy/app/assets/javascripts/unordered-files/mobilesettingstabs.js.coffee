jQuery ->
	
  $('#mobile-tabs li').removeClass 'active'
  
  wh = window.location.pathname
  
  if wh.match "edit_mobile_settings"
    $('#edit_mobile_settings-tab').addClass("active")
  else if wh.match "edit_banners"
    $('#edit_banners-tab').addClass("active")