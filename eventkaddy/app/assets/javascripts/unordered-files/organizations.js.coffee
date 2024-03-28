jQuery ->
  
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#organizations').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ -1,-2,-3,-4 ] } ]
    "iDisplayLength": 50

  $('table.dataTable th').css('padding-right','20px')
    