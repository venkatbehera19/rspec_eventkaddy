/*jslint browser: true*/
window.onload = function () {
  /* $(function () {
    $("#enabled, #disabled").sortable({
      connectWith: ".connectedSortable",
      update: function () {
        var newstatus;
        newstatus = [];
        $(this).children().each(function () {
          var column, id, input;
          column = $(this).parent().attr("id");
          id     = $(this).attr("id");
          input  = $("input", this).prop("value");
          $("#response").empty().append("Saved!").show().fadeOut(1000);
          console.log(column, id, input);
          return newstatus.push({
            id    : id,
            column: column,
            input : input
          });
        });
        return $.ajax({
          url : "update_tab",
          type: "POST",
          data: {
            Tab: JSON.stringify(newstatus)
          }
        });
      }
    })
  }); */
  $('.sortable-tabs').sortable({
    handle: ".handle",
    update: function(){
      let newstatus = updateStatus();
      $("#response").empty().append("Saved!").show().fadeOut(1000);
      return $.ajax({
        url : "update_tab",
        type: "POST",
        data: {
          Tab: JSON.stringify(newstatus)
        }
      });
    }
  });

  $('.pos-btn').on('click', function(event){
    event.stopPropagation();
    let btn = $(this);
    let currentItem = btn.parents('li');
    if (btn.attr('role') === 'up'){
      let prevItem = currentItem.prev();
      if (prevItem.length !== 0){
        currentItem.after(prevItem);
      } 
    } else if(btn.attr('role') === 'down'){
      let nextItem = currentItem.next();
      if (nextItem.length !== 0){
        currentItem.before(nextItem);
      }
    }
    
    let newstatus = updateStatus();
    $("#response").empty().append("Saved!").show().fadeOut(1000);
    return $.ajax({
      url : "update_tab",
      type: "POST",
      data: {
        Tab: JSON.stringify(newstatus)
      }
    });
  });

  $('.enabled-disabled input').change(function(){
    if ($(this).attr('checked'))
      $(this).removeAttr('checked');
    else
      $(this).attr('checked', '');
    let newstatus = updateStatus();
    $("#response").empty().append("Saved!").show().fadeOut(1000);
    return $.ajax({
      url : "update_tab",
      type: "POST",
      data: {
        Tab: JSON.stringify(newstatus)
      }
    });
  });


  $(".tab-text input").blur(function () {
    var newstatus = updateStatus();
    $("#response").empty().append("Saved!").show().fadeOut(1000);
    return $.ajax({
      url : "update_tab",
      type: "POST",
      data: {
        Tab: JSON.stringify(newstatus)
      }
    });
  });
};

function updateStatus(){
  let newstatus = [];
  $('.tab-row').each(function(){
    let column, id, input, order;
    column = $(this).find('.enabled-disabled input').attr('checked')? 'enabled' : 'disabled';
    id = $(this).find('.enabled-disabled input').attr('id');
    input = $(this).find('.tab-text input').val();
    order = $(this).index();
    return newstatus.push({
      id    : id,
      column: column,
      input : input,
      order: order
    });
  });
  return newstatus;
}