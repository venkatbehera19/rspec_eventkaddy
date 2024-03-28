jQuery ->
  
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#media_files').dataTable
  $('table.dataTable th').css('padding-right','20px')

