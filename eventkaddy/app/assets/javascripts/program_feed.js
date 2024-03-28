let sel_filter = {
  date: null,
  tag_id: [],
  search_query: null,
  selAlpha: null,
  speakerPage: 1,
  sessionPage: 1,
  exhibitorPage: 1,
  companyName: [],
  keyword: [],
  view: 'list',
  sponsor: [],
  exhibitorSponsorPage: 1,
  speakerKeynotePage: 1,
  pageType: 'ALL'
}

$(function() {
  $('.main-menu').smartmenus({
    mainMenuSubOffsetX: 1,
    mainMenuSubOffsetY: -8,
    subMenusSubOffsetX: 1,
    subMenusSubOffsetY: -8
  });
});

function getSpeakers(alphabet, event_id, search_query=null) {
  $('.alphabets.active').removeClass('active')
  if (alphabet){
    if (sel_filter.selAlpha != alphabet){
      sel_filter.speakerPage = 1
    }
    sel_filter.selAlpha = alphabet
    $(document.querySelectorAll(`[data-alpha='${alphabet}']`)[0]).addClass('active')
  }
  $.ajax({
    type: "get",
    url: `/${event_id}/program_speaker`,
    data: {alphabet: alphabet, event_id: event_id, search_query: sel_filter.search_query, speakerPage: sel_filter.speakerPage, tag_id: sel_filter.tag_id, companyName: sel_filter.companyName, speakerKeynotePage: sel_filter.speakerKeynotePage}
  });
}

function getExhibitors(alphabet, event_id, search_query=null) {
  $('.alphabets.active').removeClass('active')
  if (alphabet){
    if (sel_filter.selAlpha != alphabet){
      sel_filter.speakerPage = 1
    }
    sel_filter.selAlpha = alphabet
    $(document.querySelectorAll(`[data-alpha='${alphabet}']`)[0]).addClass('active')
  }
  url = `/${event_id}/program_exhibitor`
  if (sel_filter.pageType === 'FAVOURITE'){
    url = `/${event_id}/program_exhibitor?sel=favourite`
  }
  $.ajax({
    type: "get",
    url: url,
    data: {alphabet: alphabet, event_id: event_id, search_query: sel_filter.search_query, exhibitorPage: sel_filter.exhibitorPage, sponsor: sel_filter.sponsor, tag_id: sel_filter.tag_id, exhibitorSponsorPage: sel_filter.exhibitorSponsorPage}
  });
}

function getSponsorExhibitor(event_id) {
  url = `/${event_id}/program_sponsored_exhibitor`
  if (sel_filter.pageType === 'FAVOURITE'){
    url = `/${event_id}/program_sponsored_exhibitor?sel=favourite`
  }
  $.ajax({
    type: "get",
    url: url,
    data: {event_id: event_id, exhibitorSponsorPage: sel_filter.exhibitorSponsorPage, search_query: sel_filter.search_query, sponsor: sel_filter.sponsor, tag_id: sel_filter.tag_id}
  });
}

function getKeyoteSpeakers(event_id) {
  $.ajax({
    type: "get",
    url: `/${event_id}/program_keynote_speaker`,
    data: {event_id: event_id, search_query: sel_filter.search_query, speakerKeynotePage: sel_filter.speakerKeynotePage, tag_id: sel_filter.tag_id, companyName: sel_filter.companyName}
  });
}

function changeDate(date) {
  sel_filter.date = date
  sel_filter.sessionPage = 1
  event_id = $('#event-id').val()
  getSessions(event_id)
}

function removeFilter(id, sel_tab, type=null) {
  if(type == 'companyName'){
      index = sel_filter.companyName.indexOf(id)
      convertedID = id.replace(/[^\w]/g, "_");
      btnId = `#close_filter_company_${convertedID}`
      checkboxId = `#filter_company_${convertedID}`
      sel_filter.companyName.splice(index, 1)
      sel_filter.speakerPage = 1
    }
  else if(type == 'keyword'){
      index = sel_filter.keyword.indexOf(id)
      convertedID = id.replace(/[^\w]/g, "_");
      btnId = `#close_filter_keyword_${convertedID}`
      checkboxId = `#filter_keyword_${convertedID}`
      sel_filter.keyword.splice(index, 1)
      sel_filter.sessionPage = 1
  }
  else if(type == 'sponsor'){
    index = sel_filter.sponsor.indexOf(id.toString())
    btnId = `#close_sponsor_${id}`
    checkboxId = `#sponsor_${id}`
    sel_filter.sponsor.splice(index, 1)
    sel_filter.exhibitorPage = 1
    sel_filter.exhibitorSponsorPage = 1
  }
  else{
    index = sel_filter.tag_id.indexOf(id.toString())
    btnId = `#close_filter_tag_${id}`
    checkboxId = `#filter_tag_${id}`
    sel_filter.tag_id.splice(index, 1)
    sel_tab == 'speaker' ? sel_filter.speakerPage = 1 : sel_filter.sessionPage = 1
  }
  $(btnId).remove()
  $(checkboxId).prop('checked', false)
  event_id = $('#event-id').val()
  fetchRecord(sel_tab, event_id)
}

function fetchRecord(sel_tab, event_id) {
  if (sel_tab == 'speaker'){
    getSpeakers(null, event_id)
  }else if(sel_tab == 'schedule'){
    getSessions(event_id)
  }else if(sel_tab == 'exhibitor'){
    getExhibitors(null, event_id)
  }
}

function getSessions(event_id, tab_type=null) {
  $('.list-card-option').first().addClass('active')
  $('.list-card-option').last().removeClass('active')
  url = `/${event_id}/program`
  if (sel_filter.pageType === 'FAVOURITE'){
    url = `/${event_id}/program?sel=favourite`
  }
  $.ajax({
    type: "get",
    url: url,
    data: { event_id: event_id, date: sel_filter.date, tag_id: sel_filter.tag_id, search_query: sel_filter.search_query, tab_type: tab_type, sessionPage: sel_filter.sessionPage, keyword: sel_filter.keyword },
    beforeSend: function() {
      $('.no-record').hide()
      $('.card.mt-1').hide()
      $(".loader").removeClass('d-none')  
    },
  });
}

function getSessionsForAllDate(event_id, tab_type=null) {
  url = `/${event_id}/program`
  if (sel_filter.pageType === 'FAVOURITE'){
    url = `/${event_id}/program?sel=favourite`
  }
  $.ajax({
    type: "get",
    url: url,
    data: { event_id: event_id, date: sel_filter.date, tag_id: sel_filter.tag_id, search_query: sel_filter.search_query, tab_type: tab_type, sessionPage: sel_filter.sessionPage, keyword: sel_filter.keyword },
    beforeSend: function() {
      $('.load-more').show()
    }
  });
}

function scrollToCurrentSession() {
  currentHour = parseInt($('#current_hour').val())
  sessionHours = []
  $('.sessions-list .time-sesions').each(function(){
      sessionHours.push(parseInt($(this).attr('id').split('_').splice(-1)[0]))
  })

  index = sessionHours.indexOf(currentHour)
  if ( index !== -1){
    id = `session_at_${currentHour}`
    sessionElement = document.getElementById(id) 
    sessionElement ? sessionElement.scrollIntoView() : null
  }
  else{
    sessionHours.push(currentHour)
    sessionHours.sort(function(a, b){return a - b});
    index = sessionHours.indexOf(currentHour)
    futureHour = sessionHours[index + 1]
    id = `session_at_${futureHour}`
    sessionElement = document.getElementById(id) 
    sessionElement ? sessionElement.scrollIntoView() : null
  }
}

window.onscroll = function() {scrollFunction()};

function scrollFunction() {
  var mybutton = document.getElementById("topBtn");
  if(mybutton){
    if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
      mybutton.style.display = "block";
    } else {
      mybutton.style.display = "none";
    }
  }
}


function topFunction() {
  $('.tobesticky').hide()
  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

$(window).scroll(function(){
  sel_tab = $('.sessions_details li.nav-item a.nav-link.active').attr('data_tab_type')
  if ($(document).height() - $(this).height() - 30 <= $(this).scrollTop() && sel_tab === 'schedule'){
    event_id = $('#event-id').val()
    totalPage = parseInt($('#total_pages').val())
    sel_filter.sessionPage++
    if(sel_filter.sessionPage <= totalPage && sel_filter.date == 'ALL'){
      getSessionsForAllDate(event_id)
    }
  }
})

$(window).scroll(function(){
  scroll = $(window).scrollTop();
  if (scroll >= 100) {
      $('.time-sesions').each(function(){
          el = this
          time_header = $(this).find('.time_header')[0].getBoundingClientRect().top
          session_header = $(this).find('.session-end')[0].getBoundingClientRect().top
          if (time_header < 0 && session_header > 0){
              $(this).find('.tobesticky').show()
          }else{
              $(this).find('.tobesticky').hide()
          }
      })
  };
});                       


function showMore() {
  $('.show_more').click(function(e){
    $(this.parentElement.parentElement).find('.description').css('height', 'auto')
    $(this).hide()
    $(this.parentElement.parentElement).find('.show_less').removeClass('d-none')
  })
  $('.show_less').click(function(e){
    $(this.parentElement.parentElement).find('.description').css('height', '4.5rem')
    $(this).addClass('d-none')
    $(this.parentElement.parentElement).find('.show_more').show()
  })
}

function toCardView() {
  sel_filter.view = 'card'
  $('.sessions-list .card-body.session-body ').addClass('row')
  $('.sessions-list .card-body.session-body ').removeClass('p-0')
  $('.sessions-list .card-body.session-body ').css('padding', '0.9rem')
  $('.sessions-list .card-body .session').addClass('col-md-4')
  $('.show-more-less').removeClass('pl-3')
}

function toListView() {
  sel_filter.view = 'list'
  $('.sessions-list .card-body.session-body ').removeClass('row')
  $('.sessions-list .card-body.session-body ').addClass('p-0')
  $('.sessions-list .card-body .session').removeClass('col-md-4')
  $('.show-more-less').addClass('pl-3')
}

function crop(url, aspectRatio) {
    // we return a Promise that gets resolved with our canvas element
  return new Promise((resolve) => {
      // this image will hold our source image data
      const inputImage = new Image();

      // we want to wait for our image to load
      inputImage.onload = () => {
          // let's store the width and height of our image
          const inputWidth = inputImage.naturalWidth;
          const inputHeight = inputImage.naturalHeight;

          // get the aspect ratio of the input image
          const inputImageAspectRatio = inputWidth / inputHeight;

          // if it's bigger than our target aspect ratio
          let outputWidth = inputWidth;
          let outputHeight = inputHeight;
          if (inputImageAspectRatio > aspectRatio) {
              outputWidth = inputHeight * aspectRatio;
          } else if (inputImageAspectRatio < aspectRatio) {
              outputHeight = inputWidth / aspectRatio;
          }

          // calculate the position to draw the image at
          const outputX = (outputWidth - inputWidth) * 0.5;
          const outputY = (outputHeight - inputHeight) * 0.25;

          // create a canvas that will present the output image
          const outputImage = document.createElement('canvas');

          // set it to the same size as the image
          outputImage.width = outputWidth;
          outputImage.height = outputHeight;

          // draw our image at position 0, 0 on the canvas
          const ctx = outputImage.getContext('2d');
          ctx.drawImage(inputImage, outputX, outputY);
          resolve(outputImage);
      };

      // start loading our image
      inputImage.src = url;
  });
}

function fixImage(current) {
  img = $('.speaker-profile-pic')
  img.each(function(){
    crop(this.src, 1).then((canvas) => {
        $(this.parentElement).prepend(canvas)
    });
  })
}

$(document).ready(function(){

  $('p:empty').each(function(){
    this.remove()
  })

  pageType = $('#page-type').val()
  if (pageType === 'favourite'){
    sel_filter.pageType = 'FAVOURITE' 
  }
  
  sel_filter.date = 'ALL'
  event_id = $('#event-id').val()
  sel_tab = $('.sessions_details li.nav-item a.nav-link.active').attr('data_tab_type')
  // scrollToCurrentSession()
  showMore()
  
  $('.filters_tag').click(function(){
    var el = $(this)
    sel_tag_id = el.attr('id').split('_').splice(-1)[0]
    sel_filter.sessionPage = 1
    if($(this).is(':checked')){
      sel_filter.tag_id.push(sel_tag_id)
      $('.selected-filters').append(`<div class='close-filter pl-1 pt-1 pr-3' id='close_${el.attr('id')}'><button type="button" class="btn btn-outline-dark opened"  onclick="removeFilter(${sel_tag_id}, '${sel_tab}')"><i class="fa fa-times-circle-o pr-1" aria-hidden="true"></i>${this.dataset.parentName ? `${this.dataset.parentName} | ` : ''}${this.dataset.className}</button></div>`)
      fetchRecord(sel_tab, event_id)
    }
    else{
      removeFilter(sel_tag_id, sel_tab)
    }
  })


  $('.search_bar span#search_bar_span').click(function(){
    sel_filter.search_query = $('#search_bar').val()
    sel_tab = $('.sessions_details li.nav-item a.nav-link.active').attr('data_tab_type')
    if(sel_tab == 'speaker'){
      getSpeakers(null, event_id, sel_filter.search_query)
    }
    else if(sel_tab == 'exhibitor'){
      getExhibitors(null, event_id, sel_filter.search_query)
    }
    else{
      sel_filter.sessionPage = 1
      getSessions(event_id, sel_tab)
    }
  })

  $('input#search_bar').on("search", function() {
    sel_filter.search_query = $('#search_bar').val()
    if(sel_tab == 'speaker'){
      getSpeakers(null, event_id, sel_filter.search_query)
    }else if (sel_tab == 'exhibitor'){
      getExhibitors(null, event_id, sel_filter.search_query)
    }
    else{
      sel_filter.sessionPage = 1
      getSessions(event_id, sel_tab)
    }
  });

  $(".pagination-buttons .speaker-pagination").on("click", function () {
    if ($(this).attr("id") === "next_speakers") sel_filter.speakerPage++;
    else sel_filter.speakerPage--;
    sel_alpha = $('.alphabets.active').attr('data-alpha') || null
    getSpeakers(sel_alpha, event_id, null);
  });

  if (sel_filter.speakerPage <= 1){
    $("#prev_speakers").attr("disabled", "disabled");
  }
  if (sel_filter.speakerPage >= parseFloat($("#total_pages").val())){
    $("#next_speakers").attr("disabled", "disabled");
  }

  $(".pagination-buttons .exhibitor-pagination").on("click", function () {
    if ($(this).attr("id") === "next_exhibitors") sel_filter.exhibitorPage++;
    else sel_filter.exhibitorPage--;
    sel_alpha = $('.alphabets.active').attr('data-alpha') || null
    getExhibitors(null, event_id, null);
  });

  if (sel_filter.exhibitorPage <= 1){
    $("#prev_exhibitors").attr("disabled", "disabled");
  }
  if (sel_filter.exhibitorPage >= parseFloat($("#total_pages").val())){
    $("#next_exhibitors").attr("disabled", "disabled");
  }

  $(".pagination-buttons .sponsored-exhibitor-pagination").on("click", function () {
    if ($(this).attr("id") === "next_sponsored_exhibitors") sel_filter.exhibitorSponsorPage++;
    else sel_filter.exhibitorSponsorPage--;
    // sel_alpha = $('.alphabets.active').attr('data-alpha') || null
    getSponsorExhibitor(event_id);
  });

  if (sel_filter.exhibitorSponsorPage <= 1){
    $("#prev_sponsored_exhibitors").attr("disabled", "disabled");
  }
  if (sel_filter.exhibitorSponsorPage >= parseFloat($("#total_pages_sponsor").val())){
    $("#next_sponsored_exhibitors").attr("disabled", "disabled");
  }

  $(".pagination-buttons .keynote-speakers-pagination").on("click", function () {
    if ($(this).attr("id") === "next_keynote_speakers") sel_filter.speakerKeynotePage++;
    else sel_filter.speakerKeynotePage--;
    // sel_alpha = $('.alphabets.active').attr('data-alpha') || null
    getKeyoteSpeakers(event_id);
  });

  if (sel_filter.speakerKeynotePage <= 1){
    $("#prev_keynote_speakers").attr("disabled", "disabled");
  }
  if (sel_filter.speakerKeynotePage >= parseFloat($("#total_pages_keynote").val())){
    $("#next_keynote_speakers").attr("disabled", "disabled");
  }

  $('.collapse').on('show.bs.collapse', function () {
    parentElement = $(`.filter-option[href='#${this.id}']`)
    parentElement.find('.fa.fa-arrow-down').addClass('d-none')  
    parentElement.find('.fa.fa-arrow-up').removeClass('d-none')
  })

  $('.collapse').on('hide.bs.collapse', function () { 
    parentElement = $(`.filter-option[href='#${this.id}']`)
    parentElement.find('.fa.fa-arrow-down').removeClass('d-none')  
    parentElement.find('.fa.fa-arrow-up').addClass('d-none')
  })

  $("#companyNameSearch").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $(".company_list").filter(function() {
      $(this).toggle($(this).find('span').text().toLowerCase().indexOf(value) > -1)
    });
  });

  $("#keywordNameSearch").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $(".keyword_list").filter(function() {
      $(this).toggle($(this).find('span').text().toLowerCase().indexOf(value) > -1)
    });
  });

  $('.filters_company').click(function(){
    companyName = $(this).attr('data-class-name')
    if($(this).is(':checked')){
      sel_filter.companyName.push(companyName)
      $('.selected-filters').append(`<div class='close-filter pl-1 pt-1 pr-3' id='close_${this.id}'><button type="button" class="btn btn-outline-dark opened"  onclick="removeFilter('${companyName}', '${sel_tab}', 'companyName')"><i class="fa fa-times-circle-o pr-1" aria-hidden="true"></i>${companyName}</button></div>`)
      sel_tab == 'speaker' ? getSpeakers(null, event_id) : null
    }
    else{
      removeFilter(companyName, sel_tab, 'companyName')
    }
  })

  $('.filters_keyword').click(function(){
    keyword = $(this).attr('data-class-name')
    sel_filter.sessionPage = 1
    if($(this).is(':checked')){
      sel_filter.keyword.push(keyword)
      $('.selected-filters').append(`<div class='close-filter pl-1 pt-1 pr-3' id='close_${this.id}'><button type="button" class="btn btn-outline-dark opened"  onclick="removeFilter('${keyword}', '${sel_tab}', 'keyword')"><i class="fa fa-times-circle-o pr-1" aria-hidden="true"></i>${keyword}</button></div>`)
      sel_tab == 'speaker' ? null : getSessions(event_id)
    }
    else{
      removeFilter(keyword, sel_tab, 'keyword')
    }
  })

  $('.sponsor_level').click(function(){
    el = $(this)
    sponsor = el.attr('data-class-name')
    sponsor_id = el.attr('id').split('_').splice(-1)[0]
    sel_filter.exhibitorPage = 1
    sel_filter.exhibitorSponsorPage = 1
    if($(this).is(':checked')){
      sel_filter.sponsor.push(sponsor_id)
      $('.selected-filters').append(`<div class='close-filter pl-1 pt-1 pr-3' id='close_${this.id}'><button type="button" class="btn btn-outline-dark opened"  onclick="removeFilter('${sponsor_id}', '${sel_tab}', 'sponsor')"><i class="fa fa-times-circle-o pr-1" aria-hidden="true"></i>${sponsor}</button></div>`)
      getExhibitors(null, event_id)
    }
    else{
      removeFilter(sponsor_id, sel_tab, 'sponsor')
    }
  })

  $('body').on("click",".make-favourite", function(){
    el = this
    isFavourite = el.dataset.favourite === 'true'
    if(sel_tab === 'schedule'){
        type = 'sessions'
        record = el.dataset.session
    }else{
        type = sel_tab
        record = this.dataset.exhibitor || this.dataset.speaker
    }
    $.ajax({
      type: "post",
      url: `/${event_id}/favourite`,
      data: { event_id, type, record, isFavourite},
      beforeSend: function(){
        if(isFavourite){
          $(el).removeClass('fa-star text-danger')
        }else{
          $(el).removeClass('fa-star-o')
        }
      },
      success: function(response){
        if(isFavourite){
          $(el).attr('data-favourite', 'false');
          $(el).addClass('fa-star-o')
        }else{
          $(el).attr('data-favourite', 'true');
          $(el).addClass('fa-star text-danger')
        }
      },
      error: function(response){
        if(isFavourite){
          $(el).addClass('fa-star text-danger')
        }else{
          $(el).addClass('fa-star-o')
        }
      }

    });
  });
})