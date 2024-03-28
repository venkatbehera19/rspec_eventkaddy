# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->

  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )
  
  $('#room_layouts').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': 'nSort' },
      { 'sClass': 'd-none d-md-table-cell', 'aTargets': 'hide-on-phone' }]
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'search');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");

  $('table.dataTable th').css('padding-right','20px')