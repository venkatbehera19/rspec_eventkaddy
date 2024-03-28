let row = null;

$(document).ready(function(){
  /* Setting the dataTable */
  $('#mobile-web-settings').dataTable({
    sDom: "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>",
    "iDisplayLength": 50,
    'ordering': false,
    fnInitComplete: () => { 
      $(".dataTables_filter input").attr('placeholder', 'SEARCH');
      $(".dataTables_filter label").html($(".dataTables_filter input").clone(true, true));
      $(".dataTables_length label").html($(".dataTables_length select").clone(true, true))
        .prepend("<span class='d-none d-md-inline'>Show:</span>");
      $(".dataTables_length option[value='50']").attr('selected', 'selected')
    },
    fnDrawCallback: () => {
      /* Setting up the form on click */
      $('.edit-btn').click(function(){
        row = $(this).parent().parent();
        setForm();
      });
    }
  });

  /* Next and pre btns */
  $('.np-btns').click(function(){
    row = ($(this).attr('id') === "prev-btn") ? row.prev() : row.next();
    setForm();
  });


  /* Submiting the form */
  $('#web_setting_submit').click(function(e){
    e.preventDefault();
    $.ajax({
      type: "post",
      url: $('#edit_mob_web_settings_form').attr('action'),
      data: {
          setting_content: $('#setting_content').val(),
          device_type_id: $('#device_type_id').val(),
          position: $('#position').val(),
          enabled: $('#enabled')[0].checked,
          //type_name: $('#type_name').val()
      },
      success: function (response) {
        console.log(response.status);
        location.reload();
      }
    });
  });

});

function setForm(){
  $('#edit_mob_web_settings_form').attr('action', row.attr('url'));
    //console.log('option[value="' + $(row.children()[2]).text().replace(/ /g, '') + '"]');
  //$('#type_name').val($(row.children()[1]).text().replace(/ /g, ''))
  $('#form-type-name').text($(row.children()[1]).text().replace(/ /g, ''));
  $('#setting_content').val($(row.children()[2]).text().replace(/ /g, ''));
  let deviceTypeId = $(row.children()[3]).attr('device_type_id')
  $('#device_type_id option[value="' + deviceTypeId + '"]').attr('selected', 'selected');
  $($('#device_type_id').children()[0]).text('-- Select Device --');
  if (deviceTypeId.length === 0)
    $('#device_type_id option[selected="selected"]').removeAttr('selected');
  $('#position').val($(row.children()[5]).text());
  //console.log($(row.children()[3]).text().indexOf('true'));
  if ($(row.children()[4]).text().indexOf('true') !== -1)
    $('#enabled').attr('checked', 'true');
  else
    $('#enabled').removeAttr('checked');

  /* Check to make prev and next btns disabled */
  if (row.prev().length === 0)
    $('.np-btns#prev-btn').attr('disabled', true);
  else if (row.next().length === 0)
    $('.np-btns#next-btn').attr('disabled', true);
  else
    $('.np-btns').removeAttr('disabled');
}