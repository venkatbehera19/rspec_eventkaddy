$(document).ready(function () {
  $('#menu-toggle').click(function (e) {
    e.preventDefault()
    $('#wrapper').toggleClass('toggled')
  })
  if ($('#sidebar-wrapper').length > 0) {
    const sidebarLinks = $('.list-group-item-action')
    for (let i = 0; i < sidebarLinks.length; i++) {
      let sidebarLink = $(sidebarLinks[i])
      if (location.pathname === sidebarLink.attr('href')) {
        sidebarLink.parent().addClass('show')
        parent_btn = $('#' + sidebarLink.parent().attr('id') + '-btn')
        parent_btn.removeClass('collapsed')
        sidebarLink.addClass('active-link')
        break
      }
    }
    if (location.pathname === '/app_games/new') {
      let currentLink = $('a[href="/app_games"].list-group-item-action')
      currentLink.parent().addClass('show')
      parent_btn = $('#' + currentLink.parent().attr('id') + '-btn')
      parent_btn.removeClass('collapsed')
      currentLink.addClass('active-link')
    } else if (location.pathname === '/session_files/summary') {
      let currentLink = $(
        'a[href^="/session_files/summary"].list-group-item-action'
      )
      currentLink.parent().addClass('show')
      parent_btn = $('#' + currentLink.parent().attr('id') + '-btn')
      parent_btn.removeClass('collapsed')
      currentLink.addClass('active-link')
    }
    /* let currentLink = $('a[href^="/'+ location.pathname.split("/")[1] +  '"].list-group-item-action');
    currentLink.parent().addClass('show');
    currentLink.addClass('active-link'); */
  }
})
