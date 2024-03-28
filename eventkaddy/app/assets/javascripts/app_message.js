var json = {
  company: [],
  attendee: [],
  business_unit: [],
  exhibitor: [],
  attendee_type: [],
  survey: []
};

let removed_attendees = [], search_text, page = 1, loading = false;

$(document).ready(function(){
  $('.app_message_btn').on('click', function () {
    var button_id = $(this).attr("id");
    var input_text = $("#app_message_" + button_id).val();
    if (!(input_text==="") && button_id !== 'incomplete_survey_attendees_date' && button_id !== 'attendee_type' && button_id !== 'survey') {
      $(".selected-attendee-groups").append("<span class='badge badge-pill badge-info filter-tag'><b>" + button_id.toUpperCase().replace('_', ' ') + ":</b> " + input_text +
        "<span class='remove-filter' data-tag-type='" + button_id + "' data-tag-elem='" + input_text +"' onclick='removeFilter()'><i class='fa fa-times'></i></span>" +
      "</span>");
      json[button_id].push(input_text);
      $("#attendee_data").val(JSON.stringify(json));
      $("#app_message_" + button_id).val('');   	
    } else if (button_id === 'incomplete_survey_attendees_date'){
      if($('#date_tag').length === 0) $(".selected-attendee-groups").append("<span id='date_tag' class='badge badge-pill badge-info filter-tag'></span>");
      $('#date_tag').html("<b>" + "Incomplete Survey Attendees" + "</b>:" + $('#date').val() +
      "<span class='remove-filter' data-tag-type='" + button_id + "' data-tag-elem='" + $('#date').val() +"' onclick='removeFilter()'><i class='fa fa-times'></i></span>");
      json[button_id] = $('#date option:selected').val();
      $("#attendee_data").val(JSON.stringify(json));
    } else if(button_id === 'attendee_type'){
      let attendeeTypeName = $("#app_message_" + button_id + " option[value='" + input_text + "']").text();
      json[button_id].push(input_text);
      $(".selected-attendee-groups").append("<span class='badge badge-pill badge-info filter-tag'><b>" + button_id.toUpperCase().replace('_', ' ') + ":</b> " + attendeeTypeName +
        "<span class='remove-filter' data-tag-type='" + button_id + "' data-tag-elem='" + input_text +"' onclick='removeFilter()'><i class='fa fa-times'></i></span>" +
      "</span>");
    } else if (button_id === 'survey'){
      if($('#survey_tag').length === 0) $(".selected-attendee-groups").append("<span id='survey_tag' class='badge badge-pill badge-info filter-tag'></span>");
      $('#survey_tag').html("<b>" + "Survey" + "</b>:" + $('#survey option:selected').text() +
      "<span class='remove-filter' data-tag-type='" + button_id + "' data-tag-elem='" + $('#survey').val() +"' onclick='removeFilter()'><i class='fa fa-times'></i></span>");
      json[button_id] = $('#survey option:selected').val();
      $("#attendee_data").val(JSON.stringify(json));
    }
    return;
  });

  $('#trigger_filter').on('click', function(){
    removed_attendees = []
    page = 1;
    $('.filtered-attendees').html('<div class="spinner-border d-block mx-auto" role="status" style="margin-top: 45%;"></div>');
    $.get("/filtered_attendee_list", {filter_data: json},
      function (data, textStatus, jqXHR) {
        $('.filtered-attendees').html(data);
        if ($('.filtered-attendees').children().length > 0) $('.search-ui').removeAttr('disabled');
        $('#attendee_search').val('');
      }
    );
  });

  $('#trigger_search').on('click', function(){
    search_text = $('#attendee_search').val();
    page = 1;
    $('.filtered-attendees').html('<div class="spinner-border d-block mx-auto" role="status" style="margin-top: 45%;"></div>');
    if (search_text.length  > 0){
      $('#clear_search').show();		
      $.get("/search_and_paginate_filtered_attendees", {data: { search_text: search_text, 
        excluded_attendee_ids: removed_attendees, filter_data: json }},
        function (data, textStatus, jqXHR) {
          $('.filtered-attendees').html(data);
        }
      );
    }
  });
  
  $('#clear_search').on('click', function(){
    $('#attendee_search').val('');
    search_text = null;
    page = 1;
    $('.filtered-attendees').html('<div class="spinner-border d-block mx-auto" role="status" style="margin-top: 45%;"></div>');
    $('#clear_search').hide();
    $.get("/search_and_paginate_filtered_attendees", {data: { search_text: search_text, 
      excluded_attendee_ids: removed_attendees, filter_data: json }},
      function (data, textStatus, jqXHR) {
        $('.filtered-attendees').html(data);
      }
    );
  });

  $('.filtered-attendees').scroll(function(){
    let totalPages = parseInt($('#total_pages').val());
    if (($(this)[0].scrollHeight - $(this).scrollTop() <= $(this).outerHeight()) && !loading && page <= totalPages){
      page++;
      loading = true
      //console.log('request more');
      $.get("/search_and_paginate_filtered_attendees", {data: { search_text: search_text, 
        excluded_attendee_ids: removed_attendees, filter_data: json, page: page }},
        function (data, textStatus, jqXHR) {
          $('#total_pages').remove();
          $('.filtered-attendees').append(data);
          loading = false;
        }
      );
    }
  });

  $('#new_cms_message').submit(function(e){
    e.preventDefault();
    let title = $('#title').val();
    let content = $('#msg_content').val();
    if (areFiltersEmpty() && !confirm('Are you sure to send this messages to all attendees?'))
      return;
    $.post("/attendees/deliver_app_message_v2", {data: {title: title, content: content, filter_data: json,
      excluded_attendee_ids: removed_attendees,
      sending_attendee_id: $('#attendee_attendee_id').val()}},
      function (data, textStatus, jqXHR) {
        if (data.job_id)
          location.reload();
      }
    );
  });
});

function lazyloadImgs(){
  let elem = event.target;
  $(elem).lazyload();
}

function removeAttendee(){
  let attendeeId = $(event.target).data('attendee-id');
  console.log(attendeeId);
  removed_attendees.push(attendeeId);
  console.log(removed_attendees);
  $("#attendee_" + attendeeId).remove();
}

function removeFilter(){
  let uiElem = $(event.target).parent();
  let type = uiElem.data('tag-type');
  let elem = uiElem.data('tag-elem');

  if (type !== 'incomplete_survey_attendees_date' && type!= 'survey' ){
    json[type] = json[type].filter(el => String(el) !== String(elem));
  } else {
    json[type] = null;
  }
  uiElem.parent().remove();
};

function areFiltersEmpty(){
  for (const prop in json){
    if (json[prop].length > 0){
      return false;
    }      
  }
  return true;
}

