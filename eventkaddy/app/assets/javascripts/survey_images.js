function deleteImage(){
	var ids_arr = []
	$(".select_unselect_all").each(function(){
			checked = $(this).is(":checked")
			if(checked){
					id = $(this).attr('id')
					response_id = id.split("_")[2]
					ids_arr.push(response_id)
			}
	})

	if (ids_arr.length > 0){
		if (confirm(`Selected ${ids_arr.length} records, Confirm to delete them`)) {
			$(event.target).prepend('<span style="margin-right:10px;" class="spinner-grow spinner-grow-sm" role="status" aria-hidden="true"></span>');
			$.ajax({
				url: "/survey_images/delete_survey_images",
				type: 'get',
				data: {ids: ids_arr},
				success: function(data){
					location.reload()
				}
			})
		} else {
		}
	}else{
		alert("No Record Selected")
	}
}


function searchAttendee(survey_id){
	var input = $("#attendee_search").val()
	var completed_toggle = $("#completed_status").is(":checked")
	if (completed_toggle){
		$.ajax({
				url: `/survey_images/${survey_id}`,
				type: 'get',
				data: {attendee: input},
				success: function(data){
					$(".lazyload").lazyload();
					$(".left-image-cards").on("click", function () {
						App.toggleView(this);
					});
				}
			})
	}else{
		url = `/survey_images/attendee_list/${id}?attendee=${input}`
		fetchRecord(url)
	}
}


var page_no = 1
var id = null

function getUnattended(survey_id) {
	id = survey_id
	$("#attendee_search").val('')
	toggle = $(event.target).is(":checked")
	if (toggle){
		$("#imagesListingContainer").show()
		$("#attendee_list").hide()
		searchAttendee(survey_id)
	}else{
		$("#imagesListingContainer").hide()
		$("#attendee_list").show()
		url = `/survey_images/attendee_list/${id}?page=${page_no}`
		fetchRecord(url)
	}	
}

function paginateDown() {
  if( page_no > 1 ){
    page_no = page_no - 1
  }
  var input = $("#attendee_search").val()
  url = `/survey_images/attendee_list/${id}?page=${page_no}&attendee=${input}`
  fetchRecord(url)
}

function paginateUp() {
  total_pages = parseInt($("#total_pages").val())
  if (page_no <= total_pages){
    page_no = page_no + 1 
  }
  var input = $("#attendee_search").val()
  url = `/survey_images/attendee_list/${id}?page=${page_no}&attendee=${input}`
  fetchRecord(url)
}

function fetchRecord(url) {
	$.get(url,
		function (data, textStatus, jqXHR) {
				$("#list").html(data);
				$(".a_filters").removeAttr("disabled");
			}
		)
}


function selectUnselectResponses() {
	checked = $(event.target).is(":checked")
	if(checked){
			$(".select_unselect_all").each(function(){
				$(this).prop('checked', true)
			})
	}else{
			$(".select_unselect_all").each(function(){
				$(this).prop('checked', false)
			})
	}
}