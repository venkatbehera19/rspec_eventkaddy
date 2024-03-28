$(document).ready(function(){
  $('form.add-booth-owner').submit(function(event){
    event.preventDefault()
  })

  let searchField = document.querySelectorAll(".search-booth-attendee");
  searchField.forEach(function(elem) {
    elem.addEventListener("keypress", function(event) {
      if (event.key === "Enter") {
        event.preventDefault();
      }
    });
  });



  const exhibitor_id = $('#exhibitor_id').val()

  $("#search-available_attendees").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $(".attendee-info-available_attendees").filter(function() {
      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
    });
  });

  $("#search-booth_owners").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $(".attendee-info-booth_owners").filter(function() {
      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
    });
  });

  $(document).on('click', '.add-to-booth-owner', function(event){
    event.preventDefault()
    name = $(this.parentElement).find('p:first').text()
    el = `<li class="list-group-item justify-content-between attendee-info-booth_owners" style="display: flex;">
        <p>${name}</p>
          <button class="remove-booth-owner btn btn-outline-primary btn-sm" data-id="${this.dataset.id}"> Remove </button>
      </li>`
    $('.all-attendees-booth_owners').append(el)
    selected_arr = $('#attendee_ids').val()
    selected_arr.push(this.dataset.id)
    $('#attendee_ids').val(selected_arr)
    $(this.parentElement).remove()
    addRemoveBoothOwner(this.dataset.id, 'add')
  })


  $(document).on('click', '.remove-booth-owner', function(event){
    event.preventDefault()
    name = $(this.parentElement).find('p:first').text()
    el = `<li class="list-group-item justify-content-between attendee-info-available_attendees" style="display: flex;">
        <p>${name}</p>
        <button class="add-to-booth-owner btn btn-outline-primary btn-sm" data-id='${this.dataset.id}'> Add </button>
    </li>`
    $('.all-attendees-available_attendees').append(el)
    selected_arr = $('#attendee_ids').val()
    selected_arr = selected_arr.filter(element => element !== this.dataset.id)
    $('#attendee_ids').val(selected_arr)
    $(this.parentElement).remove()
    addRemoveBoothOwner(this.dataset.id, 'remove')
  })


  function addRemoveBoothOwner(id, type){
    $.post('/booth_owners/add_booth_owner_for_exhibitor', {attendee_id: id, exhibitor_id, type}, function(data){
    }).fail(function(){
      alert('Something Went Wrong')
    })
  }
})