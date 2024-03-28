/*jslint browser: true*/
/*global confirm*/
window.onload = function () {
  var toggleSpinner, url

  //Show spinner while saving
  toggleSpinner = function () {
    return $('#spinner').toggle()
  }
  toggleSpinner()

  //Determine view being used, needed for getting latest image
  if (/exhibitor_portals/i.test(window.location)) {
    url = '/exhibitor_portals/ajax_data'
  } else if (/messages/i.test(window.location)) {
    url = '/messages/ajax_data'
  } else if (/home_button_entries/i.test(window.location)) {
    url = '/home_button_entries/ajax_data'
  } else if (/custom_list_items/i.test(window.location)) {
    url = '/custom_list_items/ajax_data'
  } else if (/member_subscribe/i.test(window.location) || (/member_unsubscribe/i.test(window.location))) {
    url = '/settings/get_email_template_image_organization'
  } else if (/settings/i.test(window.location)) {
    url = '/settings/get_email_template_image'
  } else if (/custom_emails/i.test(window.location)) {
    url = '/settings/get_email_template_image'
  }


  //Run rails create controller to add image.
  $('#SubmitUpload').click(function () {
    if ($('#event_file').val() === '') {
      return false
    }
    $(this)
      .parent()
      .parent()
      .parent()
      .ajaxSubmit({
        beforeSubmit: function (o) {
          o.dataType = 'json'
          toggleSpinner()
        },
        complete: function () {
          $.ajax({
            type: 'GET',
            dataType: 'JSON',
            url: url,
            success: function (data) {
              if (data['path']){
                $('#gallery').append(
                  "<div class='float'><img id='"+ data["id"] +"' src='" +
                    data["path"] +
                    "'></img><p style='color:green;'>New</p></div>"
                )
              }
            }
          })
          $('#event_file').val('')
          toggleSpinner()
          $(function () {
            return $('#response')
              .html('Saved!')
              .show()
              .fadeOut(2000)
          }) //.bind('ajax:error', function (xhr, status, error) {});
        }
      })
  })

  //delete selected image
  /* $('.deleter').click(function () {
    var aurl = $(this).attr('href')

    if (confirm('Are you sure you want to delete that?')) {
      $(this)
        .parent()
        .parent()
        .remove()
      $.ajax({
        url: aurl,
        type: 'post',
        dataType: 'json',
        data: { _method: 'delete' }
      })
    } else {
      return false
    }
  }) */

  // When the page is ready:
  $(function () {
    return $('form[data-remote]')
      .bind('ajax:before', toggleSpinner)
      .bind('ajax:complete', toggleSpinner)
      .bind('ajax:success', function () {
        return $('#response')
          .html('Saved!')
          .show()
          .fadeOut(2000)
      }) //.bind('ajax:error', function (xhr, status, error) {});
  })
}
