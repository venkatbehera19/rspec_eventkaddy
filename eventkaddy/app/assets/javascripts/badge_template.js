infoForAddedOptions = {}
badgeFormData = new FormData();
storeBadgeFormFiles = {}
const fontSizes = {'1': 6, '2': 8, '3': 10, '4': 12, '5': '16'}
forBadgeSizeId = new Date().getTime()
badgeFormData.append(`badge_template[json][${forBadgeSizeId}][height]`, `300px`);
badgeFormData.append(`badge_template[json][${forBadgeSizeId}][width]`, `400px`);
badgeFormData.append(`badge_template[json][${forBadgeSizeId}][type]`, `badge_size`);

function getCoordinates(el, ui){
  childElCoordinates = el.getBoundingClientRect();
  parentElCoordinates =  $('#previewCardBadge')[0].getBoundingClientRect();
  type = el.dataset.type;
  textValue = type === 'image' ? el.dataset.value : el.textContent;
  isReverse = el.dataset.rev === 'true' ? true : false;
  infoForAddedOptions[el.id] = {
    x: (childElCoordinates.x - parentElCoordinates.x) * 2.03, 
    y: (childElCoordinates.y - parentElCoordinates.y) * 2.02,
    fontSize: el.dataset.font,
    textValue: textValue,
    type: type,
    width: childElCoordinates.width,
    height: childElCoordinates.height,
    isReverse: isReverse,
    fontType: el.dataset.fonttype,
    orientiationType: el.dataset.orientiationtype
  }
}

function addToPreview(currentOption, text, type = 'text'){
  uniqueId = new Date().getTime()
  fontSize = type !== 'qr' ? $(currentOption).parent().find('#font-size').val() : 'null'
  fontType  = $(currentOption).parent().find('#font-type').find(":selected").val()
  orientiationType  = $(currentOption).parent().find('#orientation-type').find(":selected").val()
  isReverse = $(currentOption).parent().find('#check-reverse').is(':checked');
  styleWithFont = ''
  if (fontSize !== 'null'){
    fontInPt = fontSizes[fontSize]
    fontInPx = Math.round(fontInPt * 1.3)
    styleWithFont = `style="font-size: ${fontInPx}px;"`
  }

  addEl = `<div class="static-field-badge d-flex ${type === 'qr' ? 'ui-widget-content qr-code-box' : ''}" id='${uniqueId}' data-fontType='${fontType}' data-orientiationType='${orientiationType}' data-rev='${isReverse}' data-font='${fontSize}' data-type = ${type} ${styleWithFont}>${type === 'qr' ? '<i class="fa fa-times remove-text" aria-hidden="true"></i>': ''}<p class="p-0 m-0 resize">${text}</p>${type !== 'qr' ? '<i class="fa fa-times remove-text" aria-hidden="true"></i>': ''}</div>`
  $('#previewCardBadge').prepend(addEl)
  addDraggbleToField()
  $( ".resizable" ).resizable();
}

function addDraggbleToField(){
  $( ".static-field-badge" ).draggable({
    containment: '#previewCardBadge',
    smartGuides: true,  
    appendGuideTo: '.static-field-badge:not(".selected")',
    scroll: false ,
    snapTolerance: 10,
    drag: function () {
        var $this = $(this);
        if (!$this.hasClass('selected')) {
            $this.siblings('.selected').removeClass('selected');
            $this.addClass('selected');
        }
    },
    stop: function( event, ui ) {
      getCoordinates(event.target, ui)
    }
  });
}

function addResizableToField(){
  $( ".resize-image" ).resizable({
    containment: "#previewCardBadge",
    create: function(event, ui){
      event.target.style.height = ''
    },
    stop: function(event, ui){
      event.target.style.height = ''
      getCoordinates(event.target.parentElement, ui)
    }
  });
}

function buildOption(badgeString, badgeImg){
  const badgeStringFormatted = badgeString.replaceAll('&quot;', '"').replaceAll('=&gt;', ':')
  const badgeJson = JSON.parse(badgeStringFormatted)
  const badgeImgFormatted = badgeImg.replaceAll('&quot;', '"').replaceAll('=&gt;', ':')
  const badgeImgJson = JSON.parse(badgeImgFormatted)

  infoForAddedOptions = {...badgeJson}
  
  Object.entries(infoForAddedOptions).forEach(function(option){
    id = option[0]
    optionHash = option[1]
    topPx = Math.round(parseInt(optionHash['y']) / 2.02)
    leftPx = Math.round(parseInt(optionHash['x']) / 2.03)
    width = Math.round(parseInt(optionHash['width']))
    height = Math.round(parseInt(optionHash['height']))
    fontType         = optionHash['fontType'];
    orientiationType = optionHash['orientiationType'];
    isReverse        = optionHash['isReverse']

    if(optionHash['type'] === 'qr'){
      addEl = `<div class="static-field-badge qr-code-box ui-widget-content" id="${id}" data-font="null" data-type="qr" style="left: ${leftPx}px; top: ${topPx}px;"><i class="fa fa-times remove-text" aria-hidden="true"></i>${optionHash['textValue']}</div>`
    } else if( optionHash['type'] === 'text' ) {
      addEl = `<div class="static-field-badge d-flex" id="${id}" data-font="${optionHash['fontSize']}" data-type="text" data-fontType='${fontType}' data-orientiationType='${orientiationType}' data-rev='${isReverse}' style="font-size: 21px; left: ${leftPx}px; top: ${topPx}px;"><p class="p-0 m-0">${optionHash['textValue']}</p><i class="fa fa-times remove-text" aria-hidden="true"></i></div>`
    } else if( optionHash['type'] === 'image'){
      addEl = $(`<div id='${id}' class='static-field-badge' data-type='image' data-value='${optionHash['textValue']}' style="left: ${leftPx}px; top: ${topPx}px;"><i class="fa fa-times remove-text" aria-hidden="true" style="position: absolute;top: 10px;left: 4px;border: 1px solid;background: white;height: 15px;"></i><img class='resize-image' src='${badgeImgJson[id]}' style="width: ${width}px; height: ${height}px;"></div>`)
    } else if( optionHash['type'] === 'badge_size'){
      valueString = `${parseInt(optionHash.width) / 100} X ${parseInt(optionHash.height) / 100}`;
      $('#badge-size').val(valueString).change();
      ['type', 'width', 'height'].forEach(function(e){
        badgeFormData.delete(`badge_template[json][${forBadgeSizeId}][${e}]`)
      })
      forBadgeSizeId = id
      addEl = ''
    }

    $('#previewCardBadge').prepend(addEl)
  })

  addDraggbleToField()
  addResizableToField()
  $( ".resizable" ).resizable();
}

function buildBadgeFormData(){
  for(let dataKey in infoForAddedOptions) {
    for (let previewKey in infoForAddedOptions[dataKey]) {
      if(badgeFormData.get(`badge_template[json][${dataKey}][${previewKey}]`) === null){
        badgeFormData.append(`badge_template[json][${dataKey}][${previewKey}]`, infoForAddedOptions[dataKey][previewKey]);
      }
      if(badgeFormData.get(`badge_template[json][${dataKey}][${previewKey}]`) !== infoForAddedOptions[dataKey][previewKey]){
        badgeFormData.delete(`badge_template[json][${dataKey}][${previewKey}]`)
        badgeFormData.append(`badge_template[json][${dataKey}][${previewKey}]`, infoForAddedOptions[dataKey][previewKey]);
      }
    }
  }
}

$(document).ready(function(){
  $('#previewCardBadge').droppable({
    accept:"#static-field-badge",
  });

  $( "#static-field-badge" ).draggable({
    containment: '#previewCardBadge',
    scroll: false ,
  });

  $('.add-options-to-badge').click(function(){
      text = $('#badge-static-text').val() === '' ? 'Static' : $('#badge-static-text').val()
      addToPreview(this, text)
  })

  $('.add-qr-options-to-badge').click(function() {
    text = $('#qr-code-possible-values').val()
    addToPreview(this, text, 'qr')
  })

  $('.sendRequestLabelary').click(function(){

    if(Object.keys(infoForAddedOptions).length !== 0){
      buildBadgeFormData();
      $.ajax({
        type: 'POST',
        url: '/badge_templates/fetch_preview_from_labelary',
        contentType: false,
        processData: false,
        data: badgeFormData,
        beforeSend: function(){
          $('.label-loader').show()
        },
        success: function(data){
          $('.preview-badge').show()
          var timestamp = new Date().getTime();
          $('#preview-badge-img')[0].src = window.location.origin + data.imgSrc + "?t=" + timestamp;
          $('.zpl-code').html(data.zpl_string)
          $('.label-loader').hide()
        },
        error: function(data){
          alert('Something went wrong')
        }
      })
    }else{
      alert('Nothing To Preview')
    }    
  })

  $(document).on('click', '.remove-text', function(){
    id = this.parentElement.id;
    delete infoForAddedOptions[id];
    badgeFormData.delete(`files[${id}]`);
    ['x', 'y', 'fontSize', 'textValue', 'type', 'width', 'height'].forEach(function(e){
      badgeFormData.delete(`badge_template[json][${id}][${e}]`)
    })
    this.parentElement.remove()
  })

  $('.save-template').click(function(event){
    event.preventDefault()
    name = $('#template_name').val()
    if (Object.keys(infoForAddedOptions).length === 0){
      alert('Nothing To Save')
    } else{
      buildBadgeFormData()
      badgeFormData.append('badge_template[name]', name)

      url = this.href
      type = this.dataset.methodType === 'update' ? 'PATCH' : 'POST'
      $.ajax({
        type: type,
        url: url,
        contentType: false,
        processData: false,
        data: badgeFormData,
        success: function(data){
          if (data.status === 'unprocessable_entity'){
            alert(data.message)
          }else{
            window.location = data.redirect_to
          }
        },
        error: function(data){
          alert('Something went wrong')
        }
      });
    }
  })


  $('#image-to-label').change(function(e){
    var file = this.files[this.files.length-1];
    var uniqueId = new Date().getTime()
    var img = document.createElement("img");
    img.className = 'resize-image'
    isReverse = $('#image-to-label').parent().find('#check-reverse').is(':checked');

    divForImg = $(`<div id='${uniqueId}' class='static-field-badge' data-type='image' data-rev='${isReverse}' data-value='${file.name}'><i class="fa fa-times remove-text" aria-hidden="true" style="position: absolute;top: 10px;left: 4px;border: 1px solid;background: white;height: 15px;"></div>`)
    divForImg.append(img)


    var reader = new FileReader();
    reader.onloadend = function() {
      img.src = reader.result;
    }
    
    reader.readAsDataURL(file)
    $(img).width(100).height(100);
    $('#previewCardBadge').append(divForImg[0])
    badgeFormData.append(`files[${uniqueId}]`, e.currentTarget.files[0])
    addResizableToField()
    addDraggbleToField()
  })

  $('#badge-size').change(function(){
    [width, by, height] = this.value.split(' ')
    $('#previewCardBadge').css('width', `${width  + '00px'}`)
    $('#previewCardBadge').css('height', `${height + '00px'}`)
    badgeFormData.append(`badge_template[json][${forBadgeSizeId}][height]`, `${height  + '00px'}`);
    badgeFormData.append(`badge_template[json][${forBadgeSizeId}][width]`, `${width + '00px'}`);
  })

})