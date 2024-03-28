jQuery ->
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )

  $('#exhibitor_products').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"

  $('table.dataTable th').css('padding-right','20px')

