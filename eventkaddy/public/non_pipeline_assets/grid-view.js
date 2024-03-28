
// the grid is slow because of the fetches, not the render. the render is
// actually fairly fast.

var EKSGrid = {

    sessions_data_url: '/session_grid/ajax_session_data',

    sessions_data_full: undefined,

    sessions_data: undefined,//filtered data

    date_selected: undefined,

    debug: false,

    first_fetch: true,

    // settings: {highlighted_tags: []},
    // going back, we sometimes don't have the settings in time for the grid to render...
    settings: undefined,

    menubar_height:undefined,

    table_headers_height:undefined,

    content_top_offset:undefined,

    table_width:undefined,

    filter_categories:['tags', 'title', 'sponsors', 'speakers'],

    // autocomplete_categories:['tags'],

    collectStyleValues: function() {

        EKSGrid.menubar_height       = $('.grid-menubar').first().height();
        EKSGrid.table_headers_height = $('#date_fixed').height();
        EKSGrid.content_top_offset   = EKSGrid.menubar_height + EKSGrid.table_headers_height;
        EKSGrid.table_width          = $(".grid-table").width();
    },

    initializeAutocomplete: function() {
        //let load all data on initialization for auto complete
        let full_data = [], data_types = ['title', 'tags', 'sponsors', 'speakers']
        for (let i = 0; i < data_types.length; i++){
            $.getJSON("/session_grid/ajax_session_grid_" + data_types[i] + "_only_autocomplete_data", 
                function(data){
                    data = _.reject(data, n => !n);
                    if (i=== data_types,length - 1) {
                        full_data = full_data.concat(data);
                        $("#search-input").autocomplete({ source: full_data });
                    } else {
                        full_data = full_data.concat(data);
                    }
                }
            );
        } 
        // console.log(full_data);
        // $("#search-input").autocomplete({ source: full_data.flat() });
        // $("#tag_to_color").autocomplete({ source: full_data.flat() });
        // $.getJSON("/session_grid/ajax_session_grid_tags_only_autocomplete_data", function (data) {
        //     // lose falsey values... it's bad data, but it breaks the grid, so 'repair' it
        //     data = _.reject( data, n => !n )
        //     $("#search-input").autocomplete({ source: data });
        // });

        $.getJSON("/session_grid/ajax_session_grid_tags_only_autocomplete_data", function (data) {
            // lose falsey values... it's bad data, but it breaks the grid
            data = _.reject( data, n => !n )
            $("#tag_to_color").autocomplete({ source: data });
        });
    },

    initializeSearchButton: function() {

        $("#search").click(function() {

            EKSGrid.filterSessions( $("#search-input").val(), EKSGrid.filter_categories );
            EKSGrid.showCountsOnDateButtons($("#search-input").val(), EKSGrid.filter_categories);

            if (EKSGrid.sessions_data.length===0) {
                alert("No sessions match your query for this day.");
                EKSGrid.clearTable();
                EKSGrid.fillTable();
            } else {
                EKSGrid.fillTable();
            }
        });
    },

    initializeDateButtons: function() {
        $('.date_button').on('click',function() {

            EKSGrid.toggleLoadingMessage(true,'Loading Sessions');
            EKSGrid.date_selected = this.id.split('change_date')[1];
            EKSGrid.sessions_data = $.grep( EKSGrid.sessions_data_full, function( n, i ) { return n.date.indexOf(EKSGrid.date_selected) >= 0; });

            $('.grid-topleft').html( EKSGrid.formatDate(EKSGrid.date_selected) );

            if ( history.pushState ) history.pushState( {}, 'EventKaddy CMS', 'grid_view?date=' + EKSGrid.date_selected );

            if (EKSGrid.sessions_data.length===0) {
                alert("No sessions match your query for this day.");
            } else {
                setTimeout(function() { EKSGrid.fillTable(); }, 500); //wait for loading image to fade in, then fillTable
            }

            // Current date button marking
            $('.selected-date').removeClass('selected-date');
            $('.selected-date-drop-btn').removeClass('selected-date-drop-btn');
            $(this).addClass('selected-date');
            if ($(this).parent().attr('id') === 'change-date-menu'){
                $('#change-date-dropdown > button').addClass('selected-date-drop-btn');
            }
        });
    },

    initializeLoadingLightBox: function() {

        $overlay = $('<div id="sessions_grid_overlay"></div>');
        $overlay.prependTo('body');

        // kaddy logo path added before requiring this script, via erb template
        $loading_box = $('<div id="loading_box">'                                          +
                            '<img src="'+kaddy_logo_path+'"</img><br><br><br>' +
                            '<span id="loading_message">Loading Sessions</span>'           +
                        '</div>');

        var center_pixel_left = ($(window).width()  / 2 - $loading_box.width()  / 2);
        var center_pixel_top  = ($(window).height() / 3 - $loading_box.height() / 2);

        $loading_box.prependTo('body');
        $loading_box.css({'position' : 'fixed',
                          'left'     : center_pixel_left + 'px',
                          'top'      : center_pixel_top  + 'px'});
    },

    initializeOptions: function() {

        $options_window = $('<div id="options_window" class="col-sm-5">'               +
                              '<span id="close_options"'              +
                                    'class="pull-right">'             +
                                'Close'                               +
                              '</span><br><br>'                       +
                              "<div class='field'>"                    +
                              '<input id="tag_to_color"'              +
                                     'placeholder="Tag to highlight" class="form-control" />'+
                                     '<div id="colorSelector"></div>'         +
                              '<br><br>'                      +
                              '<div id="highlight_sessions"'          +
                                   'class="btn btn-primary">'         +
                                'Highlight Sessions'               +
                              '</div>'                                +
                              "</div>"                                +
                              '<div id="legend_window_content"></div>'+
                            '</div>');

        var center_pixel_left = ($(window).innerWidth()  / 2 - $loading_box.outerWidth() / 2);
        var center_pixel_top  = ($(window).height() / 2 - $loading_box.height());

        $options_window.prependTo('body');

        $options_window.css({'position' : 'fixed',
                             'left'     : center_pixel_left + 'px',
                             'top'      : center_pixel_top  + 'px',
                            });

        $('#grid-options').on('click', function() { EKSGrid.toggleOptionsWindow(); });
        $('#close_options').on('click', function() { EKSGrid.toggleOptionsWindow(); });
        var options_position = $options_window.position();
        $('#colorSelector').jPicker({
            window:
                {
                    expandable: true,
                    position:{ x: options_position.x, y: options_position.y + 300 }
                }
        });
      // function(color, context)
      // {
      //   var all                = color.val('all');
      //   EKSGrid.tag_to_color   = $('#tag_to_color').val();
      //   EKSGrid.color_selected = (all && '#' + all.hex || 'none');
      // }

        $('#highlight_sessions').on('click', function() {

            var tag = $('#tag_to_color').val(), color = '#' + $.jPicker.List[0].color.active.val('hex');

            if (tag!=='' && tag!==undefined) {
                //// This might be broken... after change tag html to classable
                //EKSGrid.highlightSessions(tag, color);

                if (!EKSGrid.settings.highlighted_tags) EKSGrid.settings.highlighted_tags = [];

                EKSGrid.findAndRemove(EKSGrid.settings.highlighted_tags, 'tag', tag);
                EKSGrid.settings.highlighted_tags.push({tag:tag,color:color});
                EKSGrid.pushSettings();
                EKSGrid.appendLegendContent();
            }
        });
    },

    /* initializeColorLegend: function() {

        $legend_window = $('<div id="legend_window">'                       +
                              '<span id="close_legend" class="pull-right">' +
                                'Close'                                     +
                              '</span><br><br>'                             +
                              '<div id="legend_window_content"></div>'      +
                            '</div>');

        var center_pixel_left = ($(window).width()  / 2 - $loading_box.width()  / 2);
        var center_pixel_top  = ($(window).height() / 3 - $loading_box.height() / 2);

        $legend_window.prependTo('body');

        $legend_window.css({'left' : center_pixel_left + 'px',
                            'top'  : center_pixel_top  + 'px',
                            'height'   : $(window).height() / 2 + 'px'});

        $('#grid-legend').on('click', function() { EKSGrid.toggleLegendWindow(); });
        $('#close_legend').on('click', function() { EKSGrid.toggleLegendWindow(); });
    }, */

    initializeFilterOptions: function() {

        if (EKSGrid.debug) console.log("initializeFilterOptions triggered");

        $filter_options_dropdown = $('<div id="filter_options_dropdown">'                                +
                                      '<input class="autocomplete_box" type="checkbox" name="title"> Session Titles<br><br>'     +
                                      '<input class="autocomplete_box" type="checkbox" name="tags" checked> Session Tags<br><br>' +
                                      '<input class="autocomplete_box" type="checkbox" name="sponsors"> Sponsor Names<br><br>'    +
                                      '<input class="autocomplete_box" type="checkbox" name="speakers"> Speaker Names'            +
                                    '</div>');

        $filter_options_dropdown.prependTo('body');

        var p = $("#grid-filter-by").position(),
            h = $("#grid-filter-by").height(),
            top = p.top + h + 15,
            left = p.left;

        $("#filter_options_dropdown").css({top:top+"px", left:left+"px"})

        $('#grid-filter-by').on('click', function() { EKSGrid.toggleFilterOptionsDropdown(); });

        $('.autocomplete_box').on('click', function() {

            if (this.checked) {
                EKSGrid.filter_categories.push(this.name)
            } else {
                var index = EKSGrid.filter_categories.indexOf(this.name);
                if (index > -1) EKSGrid.filter_categories.splice(index, 1);
            }

            EKSGrid.reassignSearchAutocompleteData(EKSGrid.filter_categories);
        });
    },

    initializeSettings: function( cb ) {

        $.getJSON("/session_grid/ajax_get_session_grid_settings", function (data, status, xhr) {
            console.log( data, status )
            EKSGrid.settings = data;
            cb();
        });
    },

    // this never gets called?
    initializeHighlightedSessions: function() {

        if (EKSGrid.debug) console.log("initializeHighlightedSessions triggered");
        if (!EKSGrid.settings.highlighted_tags) EKSGrid.settings.highlighted_tags = [];
        $.each(EKSGrid.settings.highlighted_tags, function(i, v) { EKSGrid.highlightSessions(v.tag, v.color); });
    },

    initializeResetButton: function() {

        // this doesn't actually work! Why I wonder...
        $("#grid-reset").on('click', function() {
            $("#search-input").val("");
            EKSGrid.fillTable();
            $('.show-count').each(function(ind) {
                $(this).addClass('d-none');
            });
        });
    },

    initialize: function() {
        EKSGrid.initializeResetButton();
        //EKSGrid.initializeFilterOptions();
        EKSGrid.initializeLoadingLightBox();
        EKSGrid.initializeOptions();
        //EKSGrid.initializeColorLegend();
        EKSGrid.initializeAutocomplete();
        EKSGrid.initializeSearchButton();
        EKSGrid.initializeDateButtons();
        EKSGrid.date_selected = window.location.search.split('?date=')[1];
        if (EKSGrid.date_selected===undefined) EKSGrid.date_selected = $('.date_button').first().text().replace(/\s/g, ""); //as show count span is added the text won't just give the date have to filter spaces
        // these need to happen in order
        EKSGrid.initializeSettings(
            function() { EKSGrid.getSessionsData(); }
        );
        EKSGrid.toggleDraggable(true);

        // var tag_matches = $.grep( current_date_sessions, function( n, i ) {return n.tags.replace('&amp;','&').toLowerCase().indexOf(filter.toLowerCase()) >= 0;});

        // var $test = $("div[data-original-title*='Added Value Services']").css({'border':'3px green solid','z-index':5});
    },

    reassignSearchAutocompleteData: function(types_array) {

        var full_data = [], l = types_array.length;

        if (l===0) $("#search-input").autocomplete({ source: [] });

        $.each(types_array, function(i,v) {

            var url = "/session_grid/ajax_session_grid_" + v + "_only_autocomplete_data";

            $.getJSON(url, function (data) {

                data = _.reject( data, n => !n )

                if (i===l - 1) {
                    full_data = full_data.concat(data);
                    $("#search-input").autocomplete({ source: full_data });
                } else {
                    full_data = full_data.concat(data);
                }
            });//getJSON
        });//$.each
    },

    pushSettings: function() {

        if (EKSGrid.debug) console.log("pushSettingsTriggered");

        var send_data = { new_settings:JSON.stringify(EKSGrid.settings)};

        $.ajaxSetup({ timeout: 10000 });

        $.ajax({
            type:     'POST',
            url:      '/session_grid/ajax_push_session_grid_settings',
            dataType: 'JSON',
            data:     send_data,
            success: function(srv_data) {
                if (EKSGrid.debug) console.log("push settings ajax success");
                EKSGrid.clearTable();
                EKSGrid.fillTable();
            },
            error: function(jqXHR, textStatus, errorThrown) {

                if (EKSGrid.debug) console.log("ajax error");
                if (EKSGrid.debug) console.log(jqXHR);
                if (EKSGrid.debug) console.log(textStatus);
                if (EKSGrid.debug) console.log(errorThrown);
            }
        });
    },

    formatDate: function(date_string) {
        var months   = ['January','February','March','April','May','June','July','August','September','October','November','December']
        var weekdays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
        var date     = new Date(date_string);
        var weekday  = weekdays[date.getUTCDay()];
        var month    = months[date.getUTCMonth()];
        var day      = date.getUTCDate();
        return weekday +', ' + month + ' ' + day;
    },

    toggleOptionsWindow: function(on) {

        if (EKSGrid.debug) console.log('toggleOptionsWindow triggered');

        if ($('#options_window').css('display') === 'none') {
            var options_position = $options_window.position();
            $overlay.css({'opacity':'0.3'});
            $overlay.fadeIn(500);
            $options_window.fadeIn(500);
            EKSGrid.toggleDraggable(false);
            EKSGrid.appendLegendContent();
            // $('.jPicker.Container').css({'top':options_position.y + 300 + 'px','left':options_position.x + 'px'});
        } else {
            $overlay.fadeOut(500);
            $options_window.fadeOut(500);
            EKSGrid.toggleDraggable(true);
        }
    },

    findAndRemove: function(array, property, value) {
        $.each(array, function(index, result) {
            if (result && result[property] == value) array.splice(index, 1);
        });
    },

    findAndReturnArray: function(array, property, value) {

        var found = [];

        $.each(array, function(index, result) {
            if (result[property] == value) found.push(result);
        });

        return found;
    },

    findAndReturnTagColor: function(tag) {
        var matches = EKSGrid.findAndReturnArray(EKSGrid.settings.highlighted_tags, 'tag', tag);
        if (matches.length > 0) { return matches[0].color; } else { return '#a5e9ff'; }
    },

    getLowestNonDefaultTagColor: function(tags) {
        var color         = '#a5e9ff',
            default_color = '#a5e9ff';

        $.each(tags, function(i, tag) {
            var tag_color = EKSGrid.findAndReturnTagColor(tag);
            if (tag_color!==default_color) color = tag_color;
        });

        return color;
    },

    removeTag: function(tag) {

        if (EKSGrid.debug) console.log("removeTag triggered");

        EKSGrid.findAndRemove(EKSGrid.settings.highlighted_tags, 'tag', tag);
        EKSGrid.pushSettings();
        EKSGrid.highlightSessions(tag, '#a5e9ff');
    },

    appendLegendContent: function(){
        $('#legend_window_content').empty();
        var legend_window_content = "<div class='legend_tag'>Default</div>";

        if (EKSGrid.settings.highlighted_tags) {

            $.each(EKSGrid.settings.highlighted_tags, function(i,v) {

                var style = "background-color:" + v.color + ";color:" + EKSGrid.getContrastYIQ(v.color) + ";";
                legend_window_content += "<div class='legend_tag' style='" + style + "'>" + v.tag + "<div id='remove_" + v.tag + "' class='remove_tag pull-right'>X</div></div>";
            });

            $('#legend_window_content').append(legend_window_content);

            $('.remove_tag').on('click', function() {
                EKSGrid.removeTag(this.id.split('remove_')[1]); 
                $(this).parent().remove();
            });
        }
    },

    /* toggleLegendWindow: function(on) {

        if (EKSGrid.debug) console.log('toggleLegendWindow triggered');
        // append legend tags
        function appendLegendContent() {

            $('#legend_window_content').empty();
            var legend_window_content = "<div class='legend_tag'>Default</div>";

            if (EKSGrid.settings.highlighted_tags) {

                $.each(EKSGrid.settings.highlighted_tags, function(i,v) {

                    var style = "background-color:" + v.color + ";color:" + EKSGrid.getContrastYIQ(v.color) + ";";
                    legend_window_content += "<div class='legend_tag' style='" + style + "'>" + v.tag + "<div id='remove_" + v.tag + "' class='remove_tag pull-right'>X</div></div>";
                });

                $('#legend_window_content').append(legend_window_content);

                $('.remove_tag').on('click', function() {
                    EKSGrid.removeTag(this.id.split('remove_')[1]); $(this).parent().remove();
                });
            }
        }

        if ($('#legend_window').css('display') === 'none') {

            appendLegendContent();

            var legend_position = $legend_window.position();

            $overlay.css({'opacity':'0.3'});
            $overlay.fadeIn(500);
            $legend_window.fadeIn(500);
            EKSGrid.toggleDraggable(false);
        } else {

            $overlay.fadeOut(500);
            $legend_window.fadeOut(500);
            EKSGrid.toggleDraggable(true);
        }
    }, */

    toggleFilterOptionsDropdown: function() {

        if (EKSGrid.debug) console.log("toggleFilterOptionsDropdown triggered");

        if ($('#filter_options_dropdown').css('display') === 'none') {
            $filter_options_dropdown.fadeIn(500);
        } else {
            $filter_options_dropdown.fadeOut(500);
        }
    },

    toggleLoadingMessage: function(loading, message) {

        if (EKSGrid.debug) console.log('toggleLoadingMessage triggered');

        if (loading) {
            $('#loading_message').html(message);
            $loading_box.fadeIn(500);
            $overlay.fadeIn(500);
        } else {
            $loading_box.fadeOut(1100);
            $overlay.fadeOut(1100);
        }
    },

    toggleDraggable: function(draggable) {
        if (draggable) {

            var clicked = false, clickY, clickX;

            $(document).on({
                'mousemove': function(e) {
                    clicked && updateScrollPos(e);
                },
                'mousedown': function(e) {
                    clicked = true;
                    clickY = e.pageY;
                    clickX = e.pageX
                },
                'mouseup': function() {
                    clicked = false;
                    $('html').css('cursor', 'auto');
                }
            });

            var updateScrollPos = function(e) {
                $('html').css('cursor', 'all-scroll');
                $(window).scrollTop($(window).scrollTop() + (clickY - e.pageY));
                $(window).scrollLeft($(window).scrollLeft() + (clickX - e.pageX));
            };
        } else {
            $(document).unbind();
        }
    },

    invertColor: function(hexTripletColor) {
        var color = hexTripletColor;
        color = color.substring(1);           // remove #
        color = parseInt(color, 16);          // convert to integer
        color = 0xFFFFFF ^ color;             // invert three bytes
        color = color.toString(16);           // convert to hex
        color = ("000000" + color).slice(-6); // pad with leading zeros
        color = "#" + color;                  // prepend #
        return color;
    },

    getContrastYIQ: function(hexcolor) {
        hexcolor = hexcolor.substring(1);
        var r    = parseInt(hexcolor.substr(0,2),16);
        var g    = parseInt(hexcolor.substr(2,2),16);
        var b    = parseInt(hexcolor.substr(4,2),16);
        var yiq  = ((r*299)+(g*587)+(b*114))/1000;
        return (yiq >= 128) ? 'black' : 'white';
    },

    highlightSessions: function(tag, color) {
        $("div[data-original-title*='" + EKSGrid.replaceHTML(tag) + "']"  ).css({'background-color':color}); //,'z-index':5
        $("div[data-original-title*='" + EKSGrid.replaceHTML(tag) + "'] a").css({'color':EKSGrid.getContrastYIQ(color)  });
    },

    getSessionsData: function() {
        console.log("getSessionsDataTriggered");

        if (EKSGrid.debug) console.log("getSessionsDataTriggered");

        var send_data = { date_selected:'', event_id: event_id };

        $.ajaxSetup({ timeout: 10000 });

        $.ajax({
            type:     'GET',
            url:      EKSGrid.sessions_data_url,
            dataType: 'JSON',
            data:     send_data,
            success: function(srv_data) {
                //console.log(srv_data);
                EKSGrid.sessions_data_full = srv_data;

                EKSGrid.sessions_data = $.grep( srv_data, function( n, i ) {
                    return n.date.indexOf(EKSGrid.date_selected) >= 0;
                });
                //console.log(EKSGrid.sessions_data);

                if (EKSGrid.first_fetch) {

                    // benchmark(function fillTable() {
                        EKSGrid.fillTable();
                        EKSGrid.first_fetch = false;
                    // }, [])
                }

                EKSGrid.toggleLoadingMessage(false,'blah');
            },
            error: function(jqXHR, textStatus, errorThrown) {
                if (EKSGrid.debug) console.log("ajax error");
                if (EKSGrid.debug) console.log(jqXHR);
                if (EKSGrid.debug) console.log(textStatus);
                if (EKSGrid.debug) console.log(errorThrown);
            }
        });
    },

    addSessionElement: function(session, position, start_at_offset, session_length) {

        if (EKSGrid.debug) console.log("addSessionElement triggered");

        let tags = (session.session_tag_bloodlines || "")
        .split(/[||&&]/).map((e) => e.trim()).filter((e) => e.length > 0);
        
        var top_style        = position.top  + 39 + 116,
            left_style       = position.left + start_at_offset,
            width_style      = session_length,
            error_style      = (session_length <= 0) ? "border-color:red;z-index:1;" : "",
            thin_style_open  = (session_length < 50) ? "<div style='word-wrap: break-word;width:10px;line-height:11px;margin: 0 auto;'>" : "",
            thin_style_close = (session_length < 50) ? "</div>" : "",
            content          = (session_length > 50) ? session.title : "",
            tag_color        = EKSGrid.getLowestNonDefaultTagColor(tags);

        $('body').append("<div id='session_div" + session.id +
                              "' data-toggle='tooltip'"   +
                              // "data-placement='top' title='" + (session.tags || "").replace("'","") + "'" +
                              //.replace(/pipe/g,' ')
                              // tooltip() seems to transform this into data-original-title, but it's still very inconvenient
                              // We would really prefer not to have to rely on html attributes to make tooltips. Maybe I should just
                              // ditch this old plugin and opt for what I had in the other site
                              // Yeah, it's the bootstrap tooltip()
                              // Maybe it doesn't matter actually. You can even put html in title. must just be class and id that are particular
                              "data-placement='top' title='" + (session.session_tag_bloodlines || "").replace(/\&\&/g, ', ') + "' " +
                              "class='grid-content'"                       +
                              "style='top:"   + top_style  + "px;"        +
                                     "left:"  + left_style  + "px;"        +
                                     "width:" + width_style + "px;"        +
                                     "background-color:" + tag_color + ";" +
                                     error_style + "'>"                    +
                            "<a style='color:"+EKSGrid.getContrastYIQ(tag_color)+";' href='/sessions/" + session.id + "'>"      +
                              "<b>"                                        +
                                thin_style_open                            +
                                session.session_code                       +
                                thin_style_close                           +
                              "</b><br>"                                   +
                              content                                      +
                            "</a>"                                         +
                          "</div>");

        $('#session_div' + session.id).tooltip();
    },

    addSessionTitleToToolTip: function(session, position, start_at_offset, session_length) {

        if (EKSGrid.debug) console.log("addSessionTitleToToolTip triggered");

        var top = position.top + 90; //90 for top header

        if (session_length > 0) {

            var left = position.left - 2 + start_at_offset + (session_length / 2); //halfway point
            $('body').append("<img class='info'"                              +
                                  "id='" + session.session_code + "_tooltip'" +
                                  "src='"+info_image+"'"      +
                                  "style='top:"  + top  + "px;"               +
                                         "left:" + left + "px;'"              +
                                 "data-toggle='tooltip'"                      +
                                 "data-placement='top' title='" + session.title + "'></img>");
        } else {

            var left = position.left + 3 + start_at_offset; //session length was invalid, so center based on error_style
            $('body').append("<img class='info'"                               +
                                   "id='" + session.session_code + "_tooltip'" +
                                   "src='"+info_image+"'"      +
                                   "style='top:"  + top  + "px;"               +
                                          "left:" + left + "px;'"              +
                                   "data-toggle='tooltip'"                     +
                                   "data-placement='top' title='" + session.title + "'></img>");
        }

        $('#'+session.session_code+'_tooltip').tooltip();
    },

    clearTable: function() {

        if (EKSGrid.debug) console.log("clearTable triggered");

        var elements_to_remove = ['.grid-content', '.info', '.grid-inner', '.grid-top', '.grid-left']
        var elements_to_empty  = ['#header-fixed', '#side-header-fixed tbody']
        $.each(elements_to_remove, function(index, element) { $(element).remove(); });
        $.each(elements_to_empty, function(index, element) { $(element).empty(); });
    },

    uniqueSessionsDataOnly: function() {

        var arr = [], collection = [];

        $.each(EKSGrid.sessions_data, function (index, value) {
            if ($.inArray(value.id, arr) == -1) { arr.push(value.id); collection.push(value); }
        });

        EKSGrid.sessions_data = _.sortBy(collection, function(o) { return o.location_name; });
    },

    sortSessions: function() {
        EKSGrid.sessions_data = _.sortBy(EKSGrid.sessions_data, function(o) { return o.location_name; });
    },

    // This is probably a spot where bugs occur, for html elements that I have not accounted for
    replaceHTML: function(string) {

        // from the newer avma calendar
        function classable(string) {
            const numbers = { '1': 'one', '2': 'two', '3': 'three', '4': 'four', '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine', '0': 'zero' }
            string = string.split('').map( c => c.match( /\d/ ) ? numbers[c] : c ).join('')
            string = string.replace(/\|/g, 'pipe')
            return string.replace(/[^A-Za-z]/g,"")
        }

        return classable( string || "" )
        // return (string || "").replace('&amp;','&').replace('&#39;',"'");
    },

    returnSessionMatches: function(sessions, filter, category) {
        if (category == 'tags') category = 'session_tag_bloodlines';
        filter = EKSGrid.replaceHTML( filter ).toLowerCase();
        sessions = _.filter(sessions, function(n, i) {return n[category]!==null});
        return $.grep( sessions, function( n, i ) {return EKSGrid.replaceHTML(n[category]).toLowerCase().indexOf(filter) >= 0;});
    },

    filterSessions: function(filter, categories) {

        if (EKSGrid.debug) console.log("filterSessions triggered");

        var matches = [];

        // var current_date_sessions = $.grep( EKSGrid.sessions_data_full, function( n, i ) {
        //     return n.date.indexOf(EKSGrid.date_selected) >= 0;
        // });

        // this could just be a reduce
        $.each(categories, function(i, category) {
            matches = matches.concat(EKSGrid.returnSessionMatches(EKSGrid.sessions_data, filter, category));
        });

        EKSGrid.sessions_data = matches;//$.unique(matches);

        EKSGrid.uniqueSessionsDataOnly();
        EKSGrid.sortSessions();
        EKSGrid.toggleLoadingMessage(false, '');
    },

    showCountsOnDateButtons: function(filter, categories){
        //console.log(filter, EKSGrid.sessions_data_full);
        $(".show-count").each(function( index ) {
            $(this).addClass("d-none")}
        );
        let matches = [];
        $.each(categories, function(i, category) {
            matches = matches.concat(EKSGrid.returnSessionMatches(EKSGrid.sessions_data_full, filter, category));
        });
        //console.log(matches);
        // counts search result on each date
        let date_counts = {}
        for(let i = 0; i < matches.length;i++){
            if (date_counts[matches[i]["date"]]){
                date_counts[matches[i]["date"]]++;
            } else{
                date_counts[matches[i]["date"]] = 1; 
            }
        }
        //console.log(date_counts);
        // marking them on buttons
        for (const date in date_counts){
            let show_count = $("#change_date" + date + " .show-count");
            show_count.removeClass("d-none");
            show_count.text(date_counts[date]);
        }
        // marking on more dates button
        if ($("#change-date-menu").children().length > 0){
            let total_count = 0;
            $("#change-date-menu").children().each(function(ind){
                //console.log($(this).find(".show-count").text().length);
                total_count += parseInt($(this).find(".show-count").text().length > 0 ? $(this).find(".show-count").text() : "0");
            })
            //console.log(total_count);
            $("#change-date-dropdown > button > .show-count").removeClass('d-none').text(total_count);
        }

    },

    returnHeaderTimesArray: function() {

        if (EKSGrid.debug) console.log("returnHeaderTimesArray triggered");

        var header_times_full = [];

        $.each(EKSGrid.sessions_data, function(index, value) {

            if ($.inArray(value.start_at.slice(0,-3), header_times_full) === -1) {
                header_times_full.push(value.start_at.slice(0,-3));
            }

            if ($.inArray(value.end_at.slice(0,-3), header_times_full) === -1) {
                header_times_full.push(value.end_at.slice(0,-3));
            }
        });

        //header_times_full = $.grep(header_times_full, function (n, i) { return n.indexOf(":00") >=0}); //dont show    invalid sessions
        header_times_full.sort();
        return header_times_full;
    },

    returnUnqiueHeaderTimes: function() {

        if (EKSGrid.debug) console.log("returnUnqiueHeaderTimes triggered");

        var header_times_full       = EKSGrid.returnHeaderTimesArray();
        var header_times_unique     = [];
        var header_times_difference = header_times_full[header_times_full.length-1] - header_times_full[0];

        for (header_times_difference; header_times_difference>-1; header_times_difference--) {
            header_times_unique.push(header_times_full[header_times_full.length-1]-header_times_difference);
        };

        return header_times_unique;
    },

    addTopHeaders: function(header_times_unique) {

        if (EKSGrid.debug) console.log("addTopHeaders triggered");

        var header_times        = "";

        $.each(header_times_unique, function (index, value) {
            header_times = header_times + "<th class='grid-top'>" + value + ":00-" + value + ":59</th>"
        });

        $(".table-head tr").append(header_times);
    },

    addLeftHeaders: function(header_times_unique) {

        if (EKSGrid.debug) console.log("addLeftHeaders triggered");

        var notYetAdded = function(location_to_add, already_added) {
            return $.inArray(location_to_add, already_added) === -1;
        };

        var location_names_unique = [],
            headerroomtimes       = "",
            header_rooms          = "",
            side_header_rooms     = "";

        $.each(EKSGrid.sessions_data, function(index, value) {

            if (notYetAdded(value.location_name, location_names_unique)) {

                location_names_unique.push(value.location_name);
                header_rooms      = header_rooms      + "<tr><td class='grid-left'>" + value.location_name + "</td>";
                side_header_rooms = side_header_rooms + "<tr><td class='grid-left'>" + value.location_name + "</td></tr>";

                $.each(header_times_unique, function(index, header_time) {
                    header_rooms = header_rooms + "<td class='grid-inner " + EKSGrid.replaceHTML(value.location_name).replace(/\W/g,'') + " " + header_time + "'></td>";
                });

                header_rooms = header_rooms + "</tr>";
            }
        });

        $("#grid-body")        .append(header_rooms);
        $("#side-header-fixed").append(side_header_rooms);
    },

    addHeaders: function() {

        if (EKSGrid.debug) console.log("addHeaders triggered");

        var header_times_unique = EKSGrid.returnUnqiueHeaderTimes();
        EKSGrid.addTopHeaders(header_times_unique);
        EKSGrid.addLeftHeaders(header_times_unique);
    },

    // This is probably a big bottleneck
    getGridElement: function(session) {

        if (EKSGrid.debug) console.log("getGridElement triggered");
        //underlying grid elements have coordinates in class names based on room row they are in, and hour column
        //get the position of this element to overlay more dynamic information.
        var location_name = EKSGrid.replaceHTML(session.location_name).replace(/\W/g,'');
        var start_hour    = session.start_at.replace(':','').replace(/^(?!00[^0])0/, '').slice(0,-2);
        // Another bottle neck, don't console log.
        // <%# console.log( start_hour ) %>
        return $('.' + location_name + '.' + start_hour + '');
    },

    getGridElementPosition: function(session) {
        if (EKSGrid.debug) console.log("getGridElementPosition triggered");
        return EKSGrid.getGridElement(session).position();
    },

    fillTable: function() {

        if (EKSGrid.debug) console.log("fillTable triggered");

        function returnSessionLength(start, end) {
            //convert hours into minutes
            //subtract end_time from start_time
            //times 1 because hours are 115 pixels
            //minus 0.3px (hard coded) vertical border added for each hour
            let session_length = ((end['hour'] * 60 + parseInt(end['minutes'])) - (start['hour'] * 60 + parseInt(start['minutes'])));
            let real_session_length = session_length * (115 / 60) + parseInt(0.3 * (session_length / 60))

            return parseInt(real_session_length);
        }

        function returnStartObject(session) {
            var start_time = session.start_at.split(":");
            return {'hour':start_time[0], 'minutes':start_time[1]};
        }

        function returnEndObject(session) {
            var end_time = session.end_at.split(":");
            return {'hour':end_time[0], 'minutes':end_time[1]};
        }

        function returnStartAtOffset(start) {
            // *2 because hours are 120 pixels
            var offset = start['minutes'] * 2;
            //unless it's the beggining of the hour, account for padding.
            if (offset !== 0 ) offset = offset + 2;
            return offset;
        }

        EKSGrid.sessions_data = $.grep( EKSGrid.sessions_data_full, function( n, i ) {
            return n.date.indexOf(EKSGrid.date_selected) >= 0;
        });

        // gets emptied here I think. Which makes sense, because it's not the first fetch
        // although that's such a minor optimization I don't know why I have it
        var search = $("#search-input").val();
        if (!EKSGrid.first_fetch && search !== '') EKSGrid.filterSessions( search, EKSGrid.filter_categories );

        EKSGrid.uniqueSessionsDataOnly();

        EKSGrid.clearTable();
        EKSGrid.addHeaders();

        EKSGrid.scrollSettings();

        for (var i = 0; i < EKSGrid.sessions_data.length; i++) {

            //if(session.start_at==="00:00")session.start_at = "06:00";
            //console.log(EKSGrid.sessions_data[i]);
            var session       = EKSGrid.sessions_data[i],
              start           = returnStartObject(session),
              end             = returnEndObject(session),
              session_length  = returnSessionLength(start, end),
              start_at_offset = returnStartAtOffset(start),
              position        = EKSGrid.getGridElementPosition(session);
            //console.log(position);
            // <%# what do I need the position for? Shouldn't I just regen the table? %>
            // <%# Ah... because I'm using position absolute to place it on top of the grid. %>
            // <%# naturally this is also a bottleneck, but it shouldn't be that %>
            // <%# hard actually to just return an html string from this loop, rather than %>
            // <%# appending it immediately. Hopefully I can find an alternative to the tooltip as %>
            // <%# well, I don't want to do that via jquery %>
            EKSGrid.addSessionElement(session, position, start_at_offset, session_length);

            if (session_length < 50) {
                EKSGrid.addSessionTitleToToolTip(session, position, start_at_offset, session_length);
            }

            // EKSGrid.initializeHighlightedSessions();

            EKSGrid.toggleLoadingMessage(false,'');
        }
    },

    scrollSettings: function() {

        if (EKSGrid.debug) console.log("scrollSettings triggered");

        EKSGrid.collectStyleValues();

        function inverse(number) { return number * -1; }

        //table head scrolling top row
        // var tableOffset  = $(".grid-table").offset().top;
        // var $header      = $(".grid-table > thead").clone();
        var $fixedHeader = $("#header-fixed").append($(".grid-table > thead").clone());
        $fixedHeader.css({"min-width": EKSGrid.table_width     + "px",
                           "top":        EKSGrid.menubar_height  + "px"}); //removed width+3

        //table head scrolling left row
        var tableOffsetLeft  = $(".grid-table").offset().left+3; //removed left +3
        var $fixedHeaderLeft = $("#side-header-fixed");

        //table-head don't follow screen horizontally, grid-left don't follow vertically
        window.onscroll = function () {

            var left =  window.pageXOffset ? window.pageXOffset : document.documentElement.scrollLeft ? document.documentElement.scrollLeft : document.body.scrollLeft;
            var top  = window.pageYOffset;

            $fixedHeader.css({left: inverse(left) + "px"});
            $fixedHeaderLeft.css({top: inverse(top - EKSGrid.content_top_offset - 25) + "px"}); //where does this extra 14 come from?
        };

        //table-head follow screen vertically
        $(window).bind("scroll", function() {
            var offset = $(this).scrollTop();
            var offsetLeft = $(this).scrollLeft();

            //grid-left follow horizontally
            if (offsetLeft >= tableOffsetLeft && $fixedHeaderLeft.is(":hidden")) {
                $fixedHeaderLeft.show();
            } else if (offsetLeft < tableOffsetLeft) {
                $fixedHeaderLeft.hide();
            }
        });
    },

    fitDateButtonsInScreen: function(){
        let window_width = $(window).innerWidth();
        let date_button_width = $(".date_button").outerWidth();
        let no_of_date_buttons = $("#change-date-buttons").children().length;
        let approx_no_can_be_fit = parseInt((window_width - $("a[href='/sessions']").outerWidth()) / date_button_width) - 2;
        //console.log(window_width, approx_no_can_be_fit, $("#change-date-buttons").children().length);
        let dbtn = $("#change-date-buttons").children()[approx_no_can_be_fit - 1];
        if (no_of_date_buttons > approx_no_can_be_fit){
            for (let i = approx_no_can_be_fit - 1; i < no_of_date_buttons;i++){
                //console.log(i, no_of_date_buttons);
                let clone = $(dbtn).clone(true, true);
                let next = $(dbtn).next();
                $(dbtn).remove();
                dbtn = next;
                clone.removeClass('btn-outline-info');
                clone.addClass('dropdown-item');
                $("#change-date-dropdown .dropdown-menu").append(clone);
            }
        }
        //console.log($("#change-date-buttons").children().length);
        if ($("#change-date-dropdown .dropdown-menu").children().length > 0){
            $("#change-date-dropdown").removeClass('d-none');
            $("#change-date-dropdown").addClass('d-inline');
        }
    },

    markSelectedDateButtonOnInitialization: function () { 
        // current date button marking at time of initialization
        let current_dt_btn = $('#change_date' + c_date.split(' ')[0]);
        current_dt_btn.addClass('selected-date');
        //console.log(current_dt_btn.parent().attr('id'));
        if (current_dt_btn.parent().attr('id') === 'change-date-menu'){
            $('#change-date-dropdown > button').addClass('selected-date-drop-btn');
        }
     }

}

function benchmark( fn, args, loud ) {
    const log = loud ? alert : console.log;
    const start = new Date()
    var result  = fn.apply( null, args )
    log( fn.name, `${ Math.round( (new Date() - start) ) } milliseconds`)
    return result
}


$(function() {

    EKSGrid.initialize();

    //add fixed date to corner of grid
    $('body').append("<div id='date_fixed'>"+"</div>");
    $('#date_fixed').css({"top":$(".grid-table").offset().top + 1 + "px", "left":$(".grid-table").offset().left});
    // $('.jPicker.Container').css('position','fixed');
    $('#grid-body').css({"position": "absolute", "top": $('.grid-menubar').first().height() + $('#date_fixed').height() + $('.table-head').height() - 25 + "px"})
    //dirty hack to wait for jpicker to create it's container (for some reason does this asynchonously);
    // Is there really no callback? What am I talking about? Also this could just be done in css!
    
    /* Limiting the number of date buttons on large screen */
    EKSGrid.fitDateButtonsInScreen();
    EKSGrid.markSelectedDateButtonOnInitialization();
   
    setTimeout( function() {
        $('.jPicker.Container').css('position','fixed');
    }, 500);
});


