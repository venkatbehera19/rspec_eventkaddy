$(document).ready(function(){
  $('.media-view-type').click(function(){
    let view_type = this.getAttribute('id');
    $.ajax({
      type: "GET",
      url: "/mfiles_change_view",
      data: {view_type},
      success: function (response) {
        $('.media-files-container').html(response);
      }
    });
  });
});