# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->

#  $('#speaker-tabs li').click (e) ->
#    $('#speaker-tabs li').removeClass 'active'
#    $(e.currentTarget).addClass 'active'

  $('#speaker-tabs li a').removeClass 'active'

  wh = window.location.pathname

  if wh.match "checklist"
    $('#checklist-tab a').addClass("active")
  else if wh.match "show_contactinfo"
    $('#show_contactinfo-tab a').addClass("active")
  else if wh.match "show_travel_detail"
    $('#show_travel_detail-tab a').addClass("active")
  else if wh.match "sessions"
    $('#sessions-tab a').addClass("active")
  else if wh.match "show_payment_detail"
    $('#show_payment_detail-tab a').addClass("active")
  else if wh.match "messages"
    $('#messages-tab a').addClass("active")
  else if wh.match "contactinfo"
    $('#show_contactinfo-tab a').addClass("active")
  else if wh.match "download_pdf"
    $('#download_pdf-tab a').addClass("active")
  else if wh.match "faq"
    $('#faq-tab a').addClass("active")


  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )

  $('#speaker-sessions').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('#speaker-pdfs').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('table.dataTable th').css('padding-right','20px')
