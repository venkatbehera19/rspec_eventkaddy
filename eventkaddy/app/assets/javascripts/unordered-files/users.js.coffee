# jQuery ->

# #  console.log("users loaded")

#   $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )

#   $('#users').dataTable
#     "sDom": "<'row'<'span5'l><'span5'f>r>t<'row'<'span5'i><'span5'p>>"
#     "sPaginationType": "bootstrap"

#   $('table.dataTable th').css('padding-right','20px')


jQuery ->

  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )

  $('#users').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "bProcessing": true
    "bServerSide": true
    "sAjaxSource": $('#users').data('source')
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ -1,-2,-3 ] } ]
    "iDisplayLength": 50