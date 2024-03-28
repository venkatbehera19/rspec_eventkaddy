jQuery ->

  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#session_file_versions').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "aaSorting": [[ 3, "desc" ]]
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'search');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");

  $('table.dataTable th').css('padding-right','20px')
