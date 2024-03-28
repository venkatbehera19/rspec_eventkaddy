// poor man's module; would be easy to copy if we
// switched to webpack or something like that which converts
// node modules; otherwise a reasonable solution to namespacing

var Modules = Modules || {};

Modules.Util = (function Util() {

    function checkOverflow(el) {
        var curOverflow = el.style.overflow;
        if ( !curOverflow || curOverflow === "visible" ) {
            el.style.overflow = "hidden";
        }
        var isOverflowing = el.clientWidth < el.scrollWidth || el.clientHeight < el.scrollHeight;
        el.style.overflow = curOverflow;
        return isOverflowing;
    }

    // Increase font size until the container width or height would change
    // $el can be a group of els, as in a class query from jQuery
    //
    // pass in a function that will test the status of overflow, since it
    // may vary for different usages
    function maximizeFontSize( $el, isOverflowingTest ) {

        var i = 0;
        while ( !isOverflowingTest() ) {
            i++;
            var font_size = parseInt( $el.first().css('font-size') ) + 1;
            $el.css({
                'font-size': font_size + "px",
                'line-height': font_size * 1.3 + "px"
            });
            if (i > 200) break; // saftey for edge cases
        }

        var i = 0;
        while ( isOverflowingTest() ) {
            i++;
            var font_size = parseInt( $el.first().css('font-size') ) - 1;
            $el.css({
                'font-size': font_size + "px",
                'line-height': font_size * 1.3 + "px"
            });
            if (i > 200) break; // saftey for edge cases
        }

        // return the font size in case we want to use it to
        // make other fonts relative to this one (ie for the
        // leaderboard page)
        return parseInt( $el.first().css('font-size') )
    }

    // take a function that could increase the size of many elements
    // and one which does the reverse one step; useful if you don't
    // only care about font size
    function maximizeSize( increase, decrease, isOverflowingTest ) {

        var i = 0;
        while ( !isOverflowingTest() ) {
            i++;
            increase();
            if (i > 200) break; // saftey for edge cases
        }

        var i = 0;
        while ( isOverflowingTest() ) {
            i++;
            decrease();
            if (i > 200) break; // saftey for edge cases
        }
    }

    return {
        checkOverflow: checkOverflow,
        maximizeFontSize: maximizeFontSize,
        maximizeSize: maximizeSize
    }
})();
