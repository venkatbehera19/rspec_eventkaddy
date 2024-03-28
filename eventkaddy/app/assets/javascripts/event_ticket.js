$(function() {
  $("#event_ticket_table").dataTable({
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>",
    fnInitComplete: () => { 
        $(".dataTables_filter input").attr('placeholder', 'SEARCH');
        $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
        $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
            .prepend("<span class='d-none d-md-inline'>Show:</span>");
        //$(".dataTables_length option[value='10']").attr('selected', 'selected')
    }
  });
});