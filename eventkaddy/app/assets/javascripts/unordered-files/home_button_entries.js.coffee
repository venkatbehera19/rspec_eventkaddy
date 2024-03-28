jQuery ->
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )

  $('#home_button_entries').dataTable
    "sDom": "<'row'<'span5'l><'span5'f>r>t<'row'<'span5'i><'span5'p>>"
    "sPaginationType": "bootstrap"
    "aaSorting": [[ 2, "asc" ]]


  $('table.dataTable th').css('padding-right','20px')
