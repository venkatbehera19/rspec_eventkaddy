jQuery ->
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )
  
  $('#notifications').dataTable
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>"
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ -1 ] } ]
    "iDisplayLength": 50
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'SEARCH');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");
      $(".dataTables_length option[value='50']").attr('selected', 'selected')
      

  $('table.dataTable th').css('padding-right','20px')
  
  #filter based on status
  $('#notification_status').on('change', ->
    dataTable = $('#notifications').DataTable();
    if $(this).val() == 'select'
      dataTable.column(3).search('').draw();
    else
      dataTable.column(3).search($(this).val(), true, false).draw();
  );


  #filter based on active time
  if $('#active_time').length > 0
    dt = new Date();
    dtStr = dt.toDateString();
    $('#active_time').prepend("<option value='default'> All </option> <option value='#{dtStr}'> Today </option>" );
    $('#active_time option:first-child').attr('selected', 'selected');
    $('#active_time').on('change', ->
      dataTable = $('#notifications').DataTable();
      if $(this).val() == 'default'
        dataTable.column(2).search('').draw();
      else
        dataTable.column(2).search($(this).val(), true, true).draw();
    );

