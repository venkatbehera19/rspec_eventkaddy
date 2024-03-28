jQuery ->
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )
  
  $('#location_mappings').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ -1,-2,-3 ] } ]
    "iDisplayLength": 50
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'SEARCH');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");
      $(".dataTables_length option[value='50']").attr('selected', 'selected')

  $('table.dataTable th').css('padding-right','20px')
