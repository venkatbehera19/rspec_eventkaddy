# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->

  $('#trackowner-tabs li').removeClass 'active'

  wh = window.location.pathname

  if wh.match "landing"
    $('#main-tab').addClass("active")
  else if wh.match "sessions"
    $('#sessions-tab').addClass("active")
  else if wh.match "speakers"
    $('#speakers-tab').addClass("active")
  else if wh.match "session_files"
    $('#session_files-tab').addClass("active")


  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )

  $('table.dataTable th').css('padding-right','20px')
