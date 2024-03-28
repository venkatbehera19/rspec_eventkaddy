jQuery ->

#  console.log("sessions datatable load")

  $.extend( $.fn.dataTableExt.oStdClasses, {"sWrapper": "dataTables_wrapper form-inline table-responsive"} )

  $('#sessions').dataTable
    "sDom": "<'pull-left mr-1'f><'ml-auto'l>rt<'pull-left'i><'ml-auto'p>"
    "bProcessing": true
    "bServerSide": true
    "stateSave"  : true
    "sAjaxSource": $('#sessions').data('source')
    "aoColumnDefs": [ { 'bSortable': false, 'aTargets': [ 4, -1 ] },
      { 'sClass': 'd-none d-md-table-cell', 'aTargets': 'hide-on-mob' }]
    "iDisplayLength": 50
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

  # $('table.dataTable').css('width','700px')
    
  