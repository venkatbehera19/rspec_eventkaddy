var filterState = {
	page: 1,
	date: null,
	survey_id: null,
	attendance_status: null,
	search_text: "",
};

$(document).ready(function () {
	filterState = { ...filterState, ...getFormData() };
	fetchData();

	$("#filer_form input, select").on("change", function () {
		$(".filters").attr("disabled", "disabled");
		filterState = { ...filterState, ...getFormData() };
		filterState.page = 1;
		//console.log(filterState);
		fetchData();
	});

	$(".pagination-buttons button").on("click", function () {
		filterState = { ...filterState, ...getFormData() };
		if ($(this).attr("id") === "next_btn_report") filterState.page++;
		else filterState.page--;
		fetchData();
	});
});

function fetchData() {
	$.get(
		"/attendees/get_survey_responses",
		filterState,
		function (data, textStatus, jqXHR) {
			$(".survey-responses-container").html(data);
			$(".filters").removeAttr("disabled");
			if (filterState.page <= 1)
				$("#prev_btn_report").attr("disabled", "disabled");
			if (filterState.page >= parseInt($("#total_pages").val()))
				$("#next_btn_report").attr("disabled", "disabled");
		}
	);
}

function getFormData() {
	return {
		date: $("#dates option:selected").val(),
		survey_id: $("#survey option:selected").val(),
		attendance_status: $("#attendance_status").is(":checked"),
		search_text: $("#search").val(),
	};
}
