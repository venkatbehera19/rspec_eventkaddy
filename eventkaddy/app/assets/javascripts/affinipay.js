function setupAffiniPay(clientKey, name, email, event_id, order_id, cart_id, paymentSuccessfulModalMsg, paymentSuccessfulModalEmailMsg){
  const style = {
    'font-size': '18px',
    'border-radius': '4px',
    'padding': '0.375rem 0.75rem',
    'width': '100%',
    'box-shadow': 'none',
    'transition': 'border-color 0.2s ease-in-out',
    'outline': 'none',
    ':focus': {
      'border-color': '#4CAF50',
      'box-shadow': '0px 2px 4px rgba(76, 175, 80, 0.4)',
    }
  };
  const hostedFieldsConfiguration = {
    publicKey: clientKey,
    fields: [
      {
        selector: "#my_credit_card_field_id",
        input: {
          type: "credit_card_number",
          css: style,
          class: 'form-control'
        }
      },
      {
        selector: "#my_cvv_field_id",
        input: {
          type: "cvv",
          css: style
        }
      }
    ]
  };

  const hostedFieldsCallBack = function(state) {
    // console.log(state);
  };

  const hostedFields = window.AffiniPay.HostedFields.initializeFields(
    hostedFieldsConfiguration, hostedFieldsCallBack
  );


  $('#exhibitor-affinipay-form').on('submit', function(event){
    event.preventDefault();
    const primaryPaymentBtn = $('#primary-payment-btn');
    const postalCode        = $('#postal_code').val();
    const expYear           = $('#exp_year').val();
    const expMonth          = $('#exp_month').val();
    const address1          = $('#address_1').val();
    const city              = $('#city').val();
    const state             = $('#state').val();  
    const country           = $('#country').val();

    primaryPaymentBtn.prop("disabled", true);
    $('#loader').show();
    $('#loading-message').show();
    $('.loading-wrapper').show()

    if(!hostedFields.getState()){
      return;
    }

    const userDetails = {
      "postal_code": postalCode, 
      "exp_year": expYear, 
      "exp_month": expMonth, 
      "email": email, 
      "name": name,
      "address1" : address1,
      "city": city,
      "state": state,
      "country": country,
    }

    hostedFields.
    getPaymentToken(userDetails).
    then(function(result){
      console.log('Transaction Id', result.id);
      hostedFields.disableIframeInput("#my_credit_card_field_id");
      $.ajax({
        type: 'POST',
        url:  '/exhibitors/orders/product_payment',
        data: { 
          "payment_id": result.id,
          "event_id":   event_id,
          "order_id": order_id,
          "cart_id":  cart_id
        },
        success: function(response){
          console.log('Response', response)
          if(response.status == true){
            hostedFields.clearIframeInput("#my_credit_card_field_id");
            $('#success-modal').modal('show');
            // loader stops
            $('#loader').hide();
            $('#loading-message').hide();
            $('.loading-wrapper').hide();
            $('#user-id-cell').text(response.order_id);
            $('#transaction-id-cell').text(response.transaction_id);
            $('#email-cell').text(response.email);
            var amount = parseFloat(response.amount).toFixed(2);
            $('#amount-cell').text(`$ ${amount}`);
            var date = new Date(response.time);
            var formattedTime = formatDate(date);
            $('#time-cell').text(formattedTime);
            $('.modal-title').text("Payment Successful");
            $('#thankyou_message').text(paymentSuccessfulModalMsg);
            $('#email_info').text(paymentSuccessfulModalEmailMsg);

            $('#success-modal').on('hidden.bs.modal', function (e) {  
              window.location.replace(`${window.location.origin}/${event_id}/exhibitors/${response.transaction_id}/payment_success`);
            });
    
          }else{
            creditCardError = document.getElementById("credit_card_error");
            cvvError = document.getElementById("cvv_error");
            var card_error_code = ["card_declined", "card_declined_insufficient_funds", "card_declined_limit_exceeded", "card_expired", "card_declined_processing_error", "card_declined_hold", "card_number_invalid", "card_type_not_accepted", "card_processor_not_available", "server_error"];
            var cvv_error = ["card_cvv_incorrect", "invalid_data"];

            $('#primary-payment-btn').prop("disabled", false);
            $('#loader').hide();
            $('#loading-message').hide();
            $('.loading-wrapper').hide()
            hostedFields.enableIframeInput("#my_credit_card_field_id")
            if (response["message"].length > 0){
              for(let i = 0; i < response["message"].length; i++ ){
                if(card_error_code.includes(response["message"][i]["code"])){
                  console.log("Error", response["message"][i]["code"])
                  creditCardError.textContent = response["message"][i]["message"]
                  break;
                }else if(cvv_error.includes(response["message"][i]["code"])){
                  cvvError.textContent = response["message"][i]["message"];
                  $('#error-message-modal').modal('show');
                  $('#error-message1').text('Your CVV number entered was incorrect and your transaction was VOIDED.');
                  $('#error-message2').text('If your payment was processed, you will be refunded shortly afterward.');
                  break;
                }
                else if(response["message"][i]['code'] == "exceeds_authorized_amount"){
                  $('#failed-modal').modal('show');
                  $('#thankyou_message').text(response["message"][i]['message'])
                  break;
                }
              }
            }
            else {
              if (response["message"]["cvv_result"]){
                cvvError.textContent = `CVV ${response["message"]["cvv_result"]}`
              }
            }
          }
        },
        error: function(error){
          console.log('Error while doing the payment',error);
          $('#failed-modal').modal('show');
          $('#thankyou_message').text('Error while doing the payment')
          $('#primary-payment-btn').prop("disabled", false)
          $('#loader').hide();
          $('#loading-message').hide();
          $('.loading-wrapper').hide()
        }
      })
    }).catch(function(error){
      console.log('Error', error)
      $('#failed-modal').modal('show');
      $('#thankyou_message').text('Error while doing the payment');
      $('#primary-payment-btn').prop("disabled", false);
      $('#loader').hide();
      $('#loading-message').hide();
      $('.loading-wrapper').hide()
    })
  }); 

}

function formatDate(date){
  const day = date.getDate();
  const month = date.getMonth() + 1; // Months are zero-based
  const year = date.getFullYear();
  const minutes = date.getMinutes();
  let hours = date.getHours();
  const ampm = hours >= 12 ? 'pm' : 'am';
  hours = hours % 12;
  hours = hours ? hours : 12;
  return `${day}/${month}/${year} ${hours}.${minutes} ${ampm}`;
}

function zeroPay(event_id, transaction_id, cart_id){
  $('#exhibitor-zero-payment').on('submit', function(event){
    event.preventDefault();
    $('#loader').show();
    $('.loading-wrapper').show()
    $.ajax({
      type: 'POST',
      url:  '/exhibitors/orders/zero_payment',
      data: { 
        "event_id":   event_id,
        "transaction_id": transaction_id,
        "cart_id":  cart_id
      },
      success: function(response){
        if(response.status == true){
          $('#success-modal').modal('show');
          $('#loader').hide();
          $('#loading-message').hide();
          $('.loading-wrapper').hide()
            $('#user-id-cell').text(response.order_id);
            $('#transaction-id-cell').text(response.transaction_id);
            $('#email-cell').text(response.email);
            var amount = parseFloat(response.amount).toFixed(2);
            $('#amount-cell').text(`$ ${amount}`);
            var date = new Date(response.time);
            var day = date.getDate();
            var month = date.getMonth() + 1; // Months are zero-based
            var year = date.getFullYear();
            var hours = date.getHours();
            var minutes = date.getMinutes();
            var ampm = hours >= 12 ? 'pm' : 'am';

            hours = hours % 12;
            hours = hours ? hours : 12;

            var formattedTime = `${day}/${month}/${year} ${hours}.${minutes} ${ampm}`;
            $('#time-cell').text(formattedTime);
            $('.modal-title').text("Payment Successful");
            $('#thankyou_message').text(' Thank you for registering for COMPOST2024. we are so thrilled to have you atteend and network with the worlds best composters and equipment providers.');
            $('#email_info').text("Make sure to save both emails you just received. the Username and password for this registration are uniq to you and Not your USCC Login.");

            $('#success-modal').on('hidden.bs.modal', function (e) {  
              window.location.replace(`${window.location.origin}/${event_id}/exhibitors/${response.transaction_id}/payment_success`);
            });
        }
      },
      error: function(error){
        console.log('Error while doing the payment',error);
        $('#failed-modal').modal('show');
        $('#thankyou_message').text('Error while doing the payment');
        $('#primary-payment-btn').prop("disabled", false);
        $('#loader').show()
      }
    })
  })
}