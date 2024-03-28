$(document).ready(function(){
  let attendeeIdForPinBased = null
  let attendeeTypeForPinBased = null
  pathName = window.location.pathname.split('/').slice(0, 3).join('/')


  $('.search-attendee-btn, .search-exhibitor-btn, .search-speaker-btn').click(function(e){
    inputField = $(this.parentElement).find('input')
    searchText = inputField.val()
    attendeeType = inputField.data().type
    if(searchText.length > 0){
      $.ajax({
          type: "get",
          url: pathName + '/search_attendee',
          data: {searchText, attendeeType},
          success: function (data) {
            if (data.use_pin){
              ulEl = `<ul class="list-group" style=" max-height: 15rem; overflow-y: auto; ">`
              data.attendees.forEach(el => {
                liEl = `<li class="list-group-item d-flex justify-content-between"><span>${el.first_name} ${el.last_name}, ${el.company}</span> <a class="btn btn-primary btn-sm pin_modal" data-attendee='${el.id}' data-attendee-type='${attendeeType}' href="#" data-toggle="modal" data-target="#exampleModal">Print Badge</a></li>`
                ulEl = ulEl + liEl
              })
              ulEl + `</ul>`
            }else{
              ulEl = `<ul class="list-group" style=" max-height: 15rem; overflow-y: auto; ">`
              max_count = data.max_count === true ? 1 : data.max_count
              data.attendees.forEach(el => {
                idTobe = el.count >= max_count ? 'not-print' : 'print-badge-btn'
                btnText = el.count >= max_count ? 'NA' : 'Print Badge'
                dataSet = el.count >= max_count ? 'data-toggle="modal" data-target="#overRideModal"' : ''
                liEl = `<li class="list-group-item d-flex justify-content-between">${el.first_name} ${el.last_name}, ${el.company} <a class="btn btn-primary btn-sm ${idTobe}" data-attendee='${el.id}' data-attendee-type='${attendeeType}' ${dataSet} href="#">${btnText}</a></li>`
                ulEl = ulEl + liEl
              })
              ulEl + `</ul>`
            }
            $('.attendee-listing').html(ulEl)
          },
          error: function (data) {
            $('.for-error').text(data.error)
          }
        });
    }else{
      $('.for-error').text('Enter Something')
    }
  })



  $(document).on('click', '.print-badge-btn', function(e){
    el = e.target
    e.preventDefault()
    id = this.dataset.attendee
    attendeeType = this.dataset.attendeeType
    $.ajax({
      type: "get",
      url: pathName + `/print_badge/${id}?attendeeType=${attendeeType}`,
      success: function (data) {
        max_count = data.max_count === true ? 1 : data.max_count
        if(data.count >= max_count){
          el.classList.remove('print-badge-btn')
          el.classList.add('not-print')
          $(el).text('NA')
          el.dataset['toggle'] = 'modal'
          el.dataset['target'] = '#overRideModal'
        }
        selected_device ? writeToSelectedPrinter(data.zpl_string) : alert('Please select A Printer')
      },
      error: function (error) {
        $('.for-error').text(error.responseJSON.error)
      }
    });
  })

  $(document).on('click', '.not-print', function(e){
    e.preventDefault()
  })

  $('#exampleModal, #overRideModal').on('show.bs.modal', function (event) {
    $('#exampleModal #modal-error-pin').hide()
    $('#overRideModal #modal-error-pin').hide()
    headerLabel = $(event.relatedTarget.parentElement).find('span').text()
    attendeeIdForPinBased = event.relatedTarget.dataset.attendee
    attendeeTypeForPinBased = event.relatedTarget.dataset.attendeeType
    $('#exampleModalLabel').text(headerLabel)
  })

  $(document).on('click', '.pin-based-print-badge', function(e){
    attendeePin = $('#exampleModal .modal-body .form-group #attendee-pin').val()
    $.ajax({
      type: "post",
      url: pathName + `/print_badge_pin_based`,
      data: {attendeePin, attendeeIdForPinBased, attendeeTypeForPinBased},
      success: function (data) {
        if(data.status === 'success'){
          $('#exampleModal #modal-error-pin').hide()
          $('#exampleModal .modal-body .form-group #attendee-pin').val('') 
          $('#exampleModal').modal('hide')
          selected_device ? writeToSelectedPrinter(data.zpl_string) : alert('Please select A Printer')
        }else if (data.status === 'incorrect_pin') {
          $('#exampleModal #modal-error-pin').text('Incorrect Pin')
          $('#exampleModal #modal-error-pin').show()
        }else{
          alert(data.message || 'Something Went Wrong')
        }
      },
      error: function (error) {
        alert('Something Went Wrong')
      }
    });
  })

  $(document).on('click', '.override-based-print-badge', function(e){
    overRide = $('#overRideModal .modal-body .form-group #over-ride-pin').val()
    $.ajax({
      type: "post",
      url: pathName + `/print_badge_over_ride`,
      data: {overRide, attendeeIdForPinBased, attendeeTypeForPinBased},
      success: function (data) {
        if(data.status === 'success'){
          $('#overRideModal #modal-error-pin').hide()
          $('#overRideModal .modal-body .form-group #over-ride-pin').val('') 
          $('#overRideModal').modal('hide')
          selected_device ? writeToSelectedPrinter(data.zpl_string) : alert('Please select A Printer')
        }else if (data.status === 'incorrect_pin') {
          $('#overRideModal #modal-error-pin').text('Incorrect Pin')
          $('#overRideModal #modal-error-pin').show()
        }else{
          alert(data.message || 'Something Went Wrong')
        }
      },
      error: function (error) {
        alert('Something Went Wrong')
      }
    });
  })


})