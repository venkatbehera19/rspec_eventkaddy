// This file should eventually be brought back into
// the asset pipeline when ck_editor compile time is
// resolved.
//
// This file should be included after application.js, as
// it makes use of jQuery
//
// for replacing dropdowns that would go offscreen,
// should take an array of html snippets (with headers,
// boldness, hr lines etc) and append a closable menu to
// the screen.

function displayMenu( $menu ) {
    $menu.show()
}

function mobileMenu( choices, title ) {
    var $menu = mobileMenuContainer()
    var item
    $menu.append( "<h4>" + title + "<h4>" )
    $menu.append( "<a href='#' class='close_mobile_menu'>Close Menu</a><br><br>" )
    $menu.children('.close_mobile_menu').click(function() { $menu.hide() })
    for (var i = 0; i < choices.length; i++) {
        if (!choices[i]) continue // skip nulls
        if ( choices[i].year ) {
            item = "<div><b>" + choices[i].content + "</b></div>"
        } else if ( choices[i].month ) {
            item = "<div style='padding-left:35px;'><b>" + choices[i].content + "</b></div>"
        } else if ( choices[i].event ) {
            item = "<div><a style='padding-left:45px;' href='" + choices[i].link + "'>" + choices[i].content + "</a></div>"
        } else { // rely on content
            item = choices[i].content
        }
        $menu.append( item + "<br>" )
    }
    $('body').prepend( $menu )
    return $menu;
}

function mobileMenuContainer() {
    return $("<div class='mobile_menu_container'></div>")
}

