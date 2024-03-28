# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
	
#  $('#exhibitor-tabs li').click (e) ->
#    $('#exhibitor-tabs li').removeClass 'active'
#    $(e.currentTarget).addClass 'active'

  $('#exhibitor-tabs a').removeClass 'active'
  
  wh = window.location.pathname
  
  # hardcoded and not working for all the tabs in exhibitorportal layout
  ### if wh.match "landing"
    $('#landing-tab a').addClass("active")
  else if wh.match "show_exhibitordetails"
    $('#show_exhibitordetails-tab a').addClass("active")
  else if wh.match "messages"
    $('#messages-tab a').addClass("active")
  else if wh.match "edit_custom_content"
    $('#edit_custom_content-tab a').addClass("active")
  else if wh.match "exhibitor_products"
    $('#exhibitor_products-tab a').addClass("active")
  else if wh.match "edit_tags"
    $('#edit_tags-tab a').addClass("active") ###
  
  #loop through all the tabs and check for the active tag
  tab_container = $("#exhibitor-tabs")
  nav_items = tab_container.children()
  nav_items.each(() -> 
    #console.log("#" + this.id + " a")
    if (wh.match this.id.replace("-tab", ""))
      #console.log(this.id)
      $("#" + this.id + " a").addClass("active"))

  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )
  
  $('#speaker-sessions').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('#speaker-pdfs').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('table.dataTable th').css('padding-right','20px')
