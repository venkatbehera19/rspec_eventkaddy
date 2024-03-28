$(document).ready(function(e){
  $('.show_more').click(function(e){
    $(this.parentElement.parentElement).find('.sponsor-description').css('height', 'auto').css('height', 'auto')
    $(this).hide()
    $(this.parentElement.parentElement).find('.show_less').removeClass('d-none')
  })
  $('.show_less').click(function(e){
    $(this.parentElement.parentElement).find('.sponsor-description').css('height', 'auto').css('height', '7rem')
    $(this).addClass('d-none')
    $(this.parentElement.parentElement).find('.show_more').show()
  })

  $('.edit_cart').bind("ajax:success", onBoothAddedSucess).bind("ajax:error", () => {alert('Something Went Wrong')})
})

function addItemToCart(itemAdded, beingRemoved=false, beingUpdate=false){
  if(beingRemoved || beingUpdate){
    $(`#${itemAdded.item_id}_item`).remove()
  }
  if(!beingRemoved){
    htmlElement = `<div class="list-group-item list-group-item-action" id="${itemAdded.item_id}_item">
                  <div class="d-flex w-100 justify-content-between">
                    <h5 class="mb-1">${itemAdded.item_type}</h5>
                    <span class="p-3">$${itemAdded.item_price}</span>
                  </div>
                  <p class="mb-1">${itemAdded.item_name}</p>
                </div>`
    $('ul.list-group').append(htmlElement)
  }
}

function sortData(data) {
  return data.sort(function(a, b) {
    if (a.product_name < b.product_name) return -1;
    if (a.product_name > b.product_name) return 1;

    if (a.booth_name < b.booth_name) return -1;
    if (a.booth_name > b.booth_name) return 1;

    return 0;
  })
}

function sortDataV2(data) {
  return data.sort(function(a, b) {

    if (a.product_name < b.product_name) return -1;
    if (a.product_name > b.product_name) return 1;

    let boothNameA = a.booth_name.match(/\d+/);
    let boothNameB = b.booth_name.match(/\d+/);
    
    if (boothNameA && boothNameB) {
      let numA = parseInt(boothNameA[0]);
      let numB = parseInt(boothNameB[0]);
      if (numA < numB) return -1;
      if (numA > numB) return 1;
    }

    if (a.booth_name < b.booth_name) return -1;
    if (a.booth_name > b.booth_name) return 1;

    return 0;
  });
}

$(document).on('click', '.remove-sponsor', function(event){
  event.preventDefault()
  el = this
  user_id = $('#user_id').val()
  sponsor_id = el.dataset.product
  $.post('/transaction/exhibitor/remove_from_cart', {user_id, sponsor_id}, function(data, textStatus, jqXHR){
    if (textStatus == 'success'){
      $(`#${data.item_id}_item`).remove()
      addBtn = el.cloneNode(true);
      addBtn.className = 'btn btn-primary add-sponsor'
      addBtn.innerHTML = 'Add To Cart'
      el.parentElement.append(addBtn)
      el.remove()
      $('.HeaderCart_badge').html(data.cart_count)
    }else{
      alert('SomeThing Went Wrong')
    }
  })
});


function startPaymentCountDown(time){
  var startCountDownDate = time.replace(/-/g, '/')

  var countDownDate = new Date(startCountDownDate).getTime();

  var timerPaused = false

  // Update the count down every 1 second
  var x = setInterval(function() {

    if (!timerPaused){
      // Get today's date and time
      var now = new Date().getTime();

      // Find the distance between now and the count down date
      var distance = countDownDate - now;

      // Time calculations for days, hours, minutes and seconds
      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);

      // Display the result in the element with id="demo"
      document.getElementById("timer-text").innerHTML = minutes + "m " + seconds + "s ";

      // If the count down is finished, write some text
      if (distance < 0) {
        clearInterval(x);
        document.getElementById("timer-text").innerHTML = "EXPIRED";
        location.reload();
      }
    }
  }, 1000);
}

function onBoothAddedSucess(event, data, xhr){
  $('.form-submit-info').show()
  $('.form-submit-info').html(`<p>${data.message}</p>`)
  setTimeout(function() {
    $(".form-submit-info").fadeOut(1500);
  },1000);
  $('.HeaderCart_badge').html(data.cart_count)
  $('#lblCartCount').html(data.cart_count)
  addItemToCart(data.item_added)
}

function updateDisableButton(catagories, is_disable){
  catagories.forEach((category_id, index) => {
    let categoryButtonSelector = $(`.product-category-${category_id}`);
    categoryButtonSelector.attr('disabled', is_disable);
  })
}

function updateCounter(cart_count){
  $('.HeaderCart_badge').html(cart_count);
  $('#lblCartCount').html(cart_count);
}

$(document).ready(function(e){
  $(document).on('click', '.add-to-cart', function(event){
    event.preventDefault();
    console.log('Add to cart log', this.dataset);

    el          = this;
    productId   = el.dataset.product;
    cartId      = el.dataset.cart;
    type        = el.dataset.type;
    categoryId  = el.dataset.category;
    userId      = $('#user_id').val()

    cart = { user_id: userId, product_id: productId, cart_id: cartId, type: type, category_id: categoryId };

    $.post('/transaction/exhibitor/add_to_cart', cart, function(data, textStatus, jqXHR){
      console.log('Data', data);
      if (textStatus === 'success'){
        if (data["type"] != 'increase' && data["type"] != 'decrease' ){
          if (data["is_sponser_with_booth_selection"]){
            if (data["available_location_mapping"].length > 0){
              sortedData = sortDataV2(data["available_location_mapping"]);
              $("#booth").select2({placeholder: "Select Booth",
              width: 'resolve',
              theme: "classic"});
              $('#booth').empty();
              $.each(sortedData, function(index, value){
                $('#booth').append('<option value="' + value.booth_id + '">' + value.booth_name + ' with '+ value.product_name + ' at $' + value.product_price + '</option>');
              })
              $('#booth').trigger('change');
            }
          }
          else{
            if (data["available_location_mapping"].length > 0){
              sortedData = sortDataV2(data["available_location_mapping"]);
              $("#booth").select2({placeholder: "Select Booth",
              width: 'resolve',
              theme: "classic"});
              $('#booth').empty();
              $.each(sortedData, function(index, value){
                $('#booth').append('<option value="' + value.booth_id + '">' + value.booth_name + ' with '+ value.product_name + ' at $' + value.product_price + '</option>');
              })
              $('#booth').trigger('change');
            }else{
              $("#booth").select2({placeholder: "Select Booth",
              width: 'resolve',
              theme: "classic"});
              $('#booth').empty();
              $('#booth').trigger('change');
            }
          }
        }
        if (!data["status"]){
          alert(data["message"]);
        }
        if (data["data"]){
          updated_product_id = data["data"]["item_id"];
          let product_qunatity = $(`#product-quantity-${updated_product_id}`);
          product_qunatity.html(data["data"]["quantity"]);
        }
        if(data["status"] && data["type"] == "add"){
          var buttonSelector = $(`#product-btn-${data['data']['item_id']}`)
          $(buttonSelector).removeClass('btn-outline-primary').addClass('btn-outline-danger');
          $(buttonSelector).attr('data-type','remove');
          $(buttonSelector).text('Remove');
        }
        if(data["status"] && data["type"] == "remove"){
          var buttonSelector = $(`#product-btn-${data['data']['item_id']}`)
          $(buttonSelector).removeClass('btn-outline-danger').addClass('btn-outline-primary');
          $(buttonSelector).attr('data-type','add');
          $(buttonSelector).text('Add');
        }
        if(data["category_exclusions"] || data["category_exclusions_reverse"]){
          if (data["type"] == "add" ){
            updateDisableButton(data["category_exclusions"], true);
            updateDisableButton(data["category_exclusions_reverse"], true);
            addItemToCart(data["item_added"]);
            updateCounter(data["cart_count"]);
          }
          else if(data["type"] == "remove"){
            updateDisableButton(data["category_exclusions"], false);
            updateDisableButton(data["category_exclusions_reverse"], false);
            addItemToCart(data["item_added"], true);
            updateCounter(data["cart_count"]);
          }
          else if(data["type"] == "increase"){
            updateDisableButton(data["category_exclusions"], true);
            updateDisableButton(data["category_exclusions_reverse"], true);
            addItemToCart(data["item_added"], false, true);
            updateCounter(data["cart_count"]);
          }
          else if(data["type"] == "decrease" && data["data"]["quantity"] === 0){
            updateDisableButton(data["category_exclusions"], false);
            updateDisableButton(data["category_exclusions_reverse"], false);
            addItemToCart(data["item_added"], true);
            updateCounter(data["cart_count"]);
          }
        }

        if( data["status"] && data['is_sponser_with_booth']){
          $('.booth_add_to_cart').attr('disabled', true);
          updateCounter(data["cart_count"]);
          $('#booth').attr('disabled',true);
        }
        else{
          $('.booth_add_to_cart').attr('disabled', false);
          updateCounter(data["cart_count"]);
          $('#booth').attr('disabled',false);
        }
      }
    })
  })
})