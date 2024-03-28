jQuery ->
  
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#domains').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "bProcessing": true
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ -1,-2 ] } ]
    "iDisplayLength": 150

  $('table.dataTable th').css('padding-right','20px')


