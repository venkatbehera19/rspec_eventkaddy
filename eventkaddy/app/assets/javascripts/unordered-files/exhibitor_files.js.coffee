jQuery ->
  
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )
  
  $('#exhibitor_files').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('#exhibitor_files_summary').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "bProcessing": true
    "bServerSide": true
    "sAjaxSource": $('#exhibitor_files').data('source')
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ 3,4,5,6 ] } ]

  $('table.dataTable th').css('padding-right','20px')

