jQuery ->

  $('#settings-tabs li').removeClass 'active'

  switch window.location.pathname
    when '/settings/*'
      $('#settings-tab').addClass 'active'

    when '/event_settings/edit_event_settings'
      $( '#edit-event-settings-tab' ).addClass 'active'
    when '/event_settings/edit_event_tabs'
      $( '#edit-event-tabs-tab' ).addClass 'active'
    when '/event_settings/edit_requirements'
      $( '#edit-requirements-tab' ).addClass 'active'

    when '/settings/exhibitor_portal'
      $( '#exhibitor-portal-settings-tab' ).addClass 'active'
    when '/event_settings/edit_exhibitor_event_tabs'
      $( '#edit-exhibitor-event-tabs-tab' ).addClass 'active'

    when '/settings/cordova'
      $('#cordova-booleans-tab').addClass 'active'

    when '/settings/video_portal'
      $('#video-portal-booleans-tab').addClass 'active'
    when '/settings/video_portal_strings'
      $('#video-portal-strings-tab').addClass 'active'
    when '/settings/video_portal_styles'
      $('#video-portal-styles-tab').addClass 'active'
    when '/settings/video_portal_images'
      $('#video-portal-images-tab').addClass 'active'
    when '/settings/video_portal_reporting'
      $('#video-portal-reporting-tab').addClass 'active'
