let sortType = "desc";
let viewType = "grid_view";
let searchText = "";
$(document).ready(function(){
  $("#events-toggle-sort").click(function() {
    if (this.checked){
      sortType = "asc";
      fetchSortedEvents();
    }
    else {
      sortType = "desc";
      fetchSortedEvents();
    }
  });

  $(".event-view-type").click(function() {
    viewType = this.getAttribute("id");
    fetchSortedEvents()
  });

  $("#event-search-txt").on("input", function() {
    searchText = this.value;
    //console.log(this.value);
    fetchSortedEvents();
  });
});


function fetchSortedEvents() {
  $.ajax({
    type: "get",
    url: "/sort_search_toggle_view",
    data: {sort_type: sortType, view_type: viewType, search_text: searchText},
    success: function (response) {
      $("#events_container").children().remove();
      $("#events_container").append(response);
    },
    error: function (error) {
      console.log(error);
    }
  });
}