jQuery ->
  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline"} )
  
  $('#exhibitors').dataTable
    "sDom": "<'pull-left mr-1'f><'ml-auto'l>rt<'pull-left'i><'ml-auto'p>"
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': "sortable-off" } ]
    "order": [[$('#exhibitors tr th.order-by').index(), 'asc']]
    "iDisplayLength": 50
    "stateSave"  : true
    fnStateSaveCallback: (settings, data) ->
      localStorage.setItem "DataTables_" + settings.sInstance + "_" + settings.nTable.dataset.event, JSON.stringify(data)
      return
    fnStateLoadCallback: (settings) ->
      JSON.parse localStorage.getItem( "DataTables_" + settings.sInstance + "_" + settings.nTable.dataset.event )
    fnInitComplete: -> 
      $(".dataTables_filter input").attr('placeholder', 'SEARCH');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");
      $(".dataTables_length option[value='50']").attr('selected', 'selected')
  $('table.dataTable th').css('padding-right','20px')
