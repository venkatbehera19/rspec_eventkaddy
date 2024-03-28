type = "conference note"
jQuery ->
  
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#session_files').dataTable
    "sDom": "<'pull-left mr-1'f><'ml-auto'l>rt<'pull-left'i><'ml-auto'p>"

  $('#session_files_summary').dataTable
    "sDom": "<'pull-left mr-1'f><'ml-auto'l>rt<'pull-left'i><'ml-auto'p>"
    "bProcessing": true
    "bServerSide": true
    "sAjaxSource": $('#session_files_summary').data('source')
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': "sorting-false" },
      { 'sClass': 'd-none d-md-table-cell', 'aTargets': 'hide-on-mobile' } ]
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'search');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");
      
  $('table.dataTable th').css('padding-right','20px')

