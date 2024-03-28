var EKCoord = {

    debug: true,

    //Modal props

    map_id: undefined,

    event_id: undefined,

    room_type_id: undefined,

    $modalbody: undefined,

    datatable: undefined,

    //coordinate mapper props

    zoom_level: 0.6,

    map_editor_offset: undefined,

    map_width: undefined,

    map_height: undefined,

    current_marker_index: undefined,

    edit_flag: 0,

    rooms_data: undefined,

    ekdebugger: function(message) { if (EKCoord.debug) console.log(message); },

    getOriginalWidthOfImg: function(img_element) {

        var t = new Image();
        t.src = (img_element.getAttribute ? img_element.getAttribute("src") : false) || img_element.src;
        return t.width;
    },

    getOriginalHeightOfImg: function(img_element) {

        var t = new Image();
        t.src = (img_element.getAttribute ? img_element.getAttribute("src") : false) || img_element.src;
        return t.height;
    },

    returnRoomTypeId: function (data) {
        if (data.length > 0 ) { var room_type_id = data[0].location_mapping.mapping_type; }
        else { var room_type_id = 1; }
    },

    setVariablesAndLoadRooms: function(map_id) {

        EKCoord.map_id = map_id;
        // EKCoord.room_type_id = EKCoord.returnRoomTypeId();
        EKCoord.loadModalRoomsDatatable();
    },

    addRoom: function(name) {

        EKCoord.ekdebugger('addRoom triggered');

        if (name!="") {
            var room;
            room = [];
            room.push({
                name         : name,
                event_id     : EKCoord.event_id,
                map_id       : EKCoord.map_id,
                room_type_id : EKCoord.room_type_id
            });

            return $.ajax({
                url : "/room_coordinates_wizard/create_room",
                type: "POST",
                data: { Room: JSON.stringify(room) },
                success: function (data) {

                    var rowNode = EKCoord.datatable.fnAddData( [
                        name,
                        "",
                        "<center><button data-deletelink='/room_coordinates_wizard/ajax_remove_room_map_id/" + data.location_mapping.id + "' class='btn delete deleter'>Delete</button></center>"
                    ] );//.draw().node();
                    $( rowNode ).addClass("new-row");
                        // EKCoord.datatable.jumpToData( name, 0 );
                    $("#room_input").val("");
                },
                error: function(xhr){
                    var errors, message, _results;
                    errors = xhr.responseJSON.error;
                    _results = [];
                    for (message in errors) {
                        _results.push('' + errors[message] + ' ');
                    }
                    alert(_results);
                }
            });
        }
    },

    deleteRoom: function(that) {

        var aurl = $(that).attr("data-deletelink");

        if (confirm('Are you sure you want to remove this room from the event map?')) {

            $.ajax({
                url     : aurl,
                type    : "post",
                data    : {"_method": "delete"},
                success : function () {
                    $(that).parents('tr').remove();
                }
            });
        } else {
            return false;
        }
    },

    initializeRoomsAutocomplete: function() {
        $.get('/room_coordinates_wizard/ajax_array_of_all_location_mappings', function (room_names) {
            $("#room_input").autocomplete({ source: room_names });
        });
    },

    initialize: function(event_id) {

        EKCoord.ekdebugger('EKCoord.initialize Triggered');

        EKCoord.event_id = event_id;

        EKCoord.initializeRoomsAutocomplete();
    },

    emptyModalBody: function() {
        EKCoord.$modalbody = $( "#room-modal-" + EKCoord.map_id + " > .modal-body" );
        EKCoord.$modalbody.empty();
    },

    appendTable: function(data) {

        var table_data =
            "<table id='coordinates_gui_datatable' cellpadding='0' cellspacing='0' border='0' class='table table-hover table-bordered table-striped'>" +
                "<thead>" +
                    "<tr>" +
                        "<th style='width:50px;'>Location Name</th>" +
                        "<th></th>" +
                        "<th></th>" +
                    "</tr>" +
                "</thead>" +
                "<tbody>";

        $.each(data, function (index, value) {
            table_data =
                table_data +
                    "<tr>" +
                        "<td>" + value.location_mapping.name + "</td>" +
                        "<td style='text-align:center;'>" +
                            "<button id='" + index + "' class='btn show locmapping' onClick='EKCoord.startCoordinatesGui("+index+");'>Show</button>" +
                        "</td>" +
                        "<td style='text-align:center;'>" +
                            "<button data-deletelink='/room_coordinates_wizard/ajax_remove_room_map_id/" + value.location_mapping.id + "' class='btn delete deleter'>Delete</button>" +
                        "</td>" +
                    "</tr>";
        });

        table_data = table_data + "</tbody></table>";

        EKCoord.$modalbody.append(table_data);
    },

    returnDataTable: function() {

        //Must define datatable options here, definitions in location_mappings.js.coffee won't trigger
        var table = $( "#coordinates_gui_datatable" ).DataTable({
                "sDom"            : "<'pull-left'l><'pull-right'f>rt<'pull-left'i><'pull-right'p>",
                "sPaginationType" : "bootstrap",
                "aoColumnDefs"    : [ { 'bSortable': false, 'aTargets': [ 1,2 ] } ],
                "bLengthChange"   : false,
                'iDisplayLength'  : 5,
        });
        return table;
    },

    addModalControls: function() {

        EKCoord.$modalbody.prepend(
            "<div class='row'>"                                              +
                "<div class='pull-left'><button id='add_coordinates_button'" +
                        "class='btn btn-primary'>"                           +
                            "Add Coordinates for Rooms"                      +
                "</button> "                                                 +
                "<a data-toggle='modal'"                                     +
                   "href='#coordinfo'"                                       +
                   "class='btn btn-lg show'>"                                +
                        "How to Use"                                         +
                "</a></div>"                                                 +
                "<div class='pull-right'><input id='room_input'"             +
                       "type='text'"                                         +
                       "class='gui-input form-control-lg'"                       +
                       "placeholder='Enter Room Name'>"                      +
                "</input>"                                                   +
                "<button id='room_input_button'"                             +
                        "class='btn btn-primary gui-button'>"                +
                            "Add Room"                                       +
                "</button></div>"                                            +
            "</div>"                                                         +
            "<div id='response' style='inline-block'></div>"
        );

        $("#add_coordinates_button")[0].addEventListener("click", function() {EKCoord.startCoordinatesGui(0)});

        $("#room_input").bind('keyup', 'return', function(){
            EKCoord.addRoom($("#room_input").val());
        });

        $("#room_input_button")[0].addEventListener("click", function() {
            EKCoord.addRoom($("#room_input").val())
        });

        $( "#coordinates_gui_datatable" ).on('click', '.deleter', function () { EKCoord.deleteRoom(this) });

        $( "#room-modal-" + EKCoord.map_id + " .modal-header .close").on('click', function() {
            $( "#coordinates_gui_datatable" ).dataTable().fnDestroy(true);
        });

        $( "#room-modal-" + EKCoord.map_id + " .modal-footer #room-modal-close").on('click', function() {
            $( "#coordinates_gui_datatable" ).dataTable().fnDestroy(true);
        });
    },

    loadModalRoomsDatatable: function() {

        EKCoord.ekdebugger('loadModalRoomsDatatable triggered');

        EKCoord.emptyModalBody();

        var url = "/room_coordinates_wizard/ajax_room_data/" + EKCoord.map_id;

        $.get(url, function (data) {

            EKCoord.room_type_id = EKCoord.returnRoomTypeId(data);
            EKCoord.appendTable(data);
            EKCoord.datatable = EKCoord.returnDataTable();
            EKCoord.addModalControls();
        });
    },

    appendMapEditor: function(map_image_path) {

        var offset = EKCoord.$modalbody.offset();

        EKCoord.$modalbody.siblings(".modal-content").prepend(
            "<div id='map_editor' class='span12'>"                     +
                "<button id='editmode'"                                +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 5 ) + "px;'>"  +
                            "View (M)ode On"                           +
                "</button>"                                            +
                "<button id='previous'"                                +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 140) + "px;'>" +
                            "P(r)evious"                               +
                "</button>"                                            +
                "<button id='next'"                                    +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 235) + "px;'>" +
                            "Nex(t)"                                   +
                "</button>"                                            +
                "<select id='currentmarker'"                           +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 310) + "px;'>" +
                "</select>"                                            +
                "<div id='currentzoom'"                                +
                     "class='coord-button'"                            +
                     "style='left:" + (offset.left + 760) + "px;'>"    +
                "</div>"                                               +
                "<button id='zoomout'"                                 +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 665) + "px;'>" +
                            "Zoom (O)ut"                               +
                "</button>"                                            +
                "<button id='zoomin'"                                  +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 810) + "px;'>" +
                            "Zoom (I)n"                                +
                "</button>"                                            +
                "<button id='exit'"                                    +
                        "class='coord-button'"                         +
                        "style='left:" + (offset.left + 900) + "px;'>" +
                            "E(x)it"                                   +
                "</button>"                                            +
                "<div id='image-wrapper'>"                             +
                    "<img src='" + map_image_path + "'</img>"          +
                "</div>"                                               +
            "</div>"
        );

        $('#map_editor, #image-wrapper').dragscrollable({
            dragSelector: 'img',
            acceptPropagatedEvent: false
        });
    },

    setMapWidthAndHeight: function() {

        $('#image-wrapper img').load(function () {

            $('#image-wrapper').css('width', EKCoord.getOriginalWidthOfImg(this) );

            EKCoord.map_width  = EKCoord.getOriginalWidthOfImg(this);
            EKCoord.map_height = EKCoord.getOriginalHeightOfImg(this);

            $('#image-wrapper').css({
                width  : $('#image-wrapper img').width (EKCoord.map_width  * EKCoord.zoom_level),
                height : $('#image-wrapper img').height(EKCoord.map_height * EKCoord.zoom_level)
            });

            $('#currentzoom').html( (EKCoord.zoom_level * 100 + '%') );
        });
    },

    appendUnsetOption: function(id, text, index) {
        $('#currentmarker').append( $('<option id="option-' + id + '">').text(text).attr('value', index).css('background-color','red') );
    },

    appendSetOption: function(id, text, index) {
        $('#currentmarker').append( $('<option id="option-' + id + '">').text(text).attr('value', index) );
    },

    addOptionElementsToGuiSelect: function() {

        $.each(EKCoord.rooms_data, function (index, value) {

            var location_mapping_coordinates_are_not_set = value.location_mapping.x===0 || value.location_mapping.x===null && value.location_mapping.y===0 || value.location_mapping.y===null

            if (location_mapping_coordinates_are_not_set) {
                EKCoord.appendUnsetOption(value.location_mapping.id, value.location_mapping.name.replace(/&amp;/g,'&'), index);
            } else {
                EKCoord.appendSetOption(value.location_mapping.id, value.location_mapping.name.replace(/&amp;/g,'&'), index);
            }
        });
    },

    highlightCurrentMarker: function() {

        if (EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.x>0 && (EKCoord.edit_flag===1 || EKCoord.edit_flag===0)) {

            $('#marker-' + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id + '').css({
                "background-color"    : "yellow"
            });

            var $marker = $('#marker-' + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id + ''),
                $caption = $('div.caption', $marker);
            $caption.slideDown(300);
        }

        $('#map_editor').scrollTo($marker, 800, {offset: {top:-310, left:-455} });
    },

    unhighlightAndToggleCaption: function() {

        $('#marker-' + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id + '').css({
            "background-color" : "red"
        });

        var $marker = $('#marker-' + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id + ''),
            $caption = $('div.caption', $marker);
        $caption.slideUp(300);
    },

    Markers: {
        fn: {
            addMarkers: function() {

                var target   = $('#image-wrapper');
                var captions = EKCoord.rooms_data;

                for (var i = 0; i < EKCoord.rooms_data.length; i++) {

                    var obj  = EKCoord.rooms_data[i];
                    var top  = (obj.location_mapping.y - 10) * EKCoord.zoom_level;
                    var left = (obj.location_mapping.x - 10) * EKCoord.zoom_level;
                    var text =  obj.location_mapping.name;//.replace(/&amp;/g,'&');

                    $('<span class="marker" id="marker-' + obj.location_mapping.id + '"></span>').css({
                            top    : top,
                            left   : left,
                            width  : 20 * EKCoord.zoom_level + "px",
                            height : 20 * EKCoord.zoom_level + "px"
                    }).html('<div class="caption">' + text + '</div>').appendTo(target);
                }

                $('.markericon').css({'font-size': 20 * EKCoord.zoom_level + "px"});

                this.showCaptions();
                $('#currentmarker').val(EKCoord.current_marker_index).change();
                EKCoord.highlightCurrentMarker();

            },

            showCaptions: function() {
                $('span.marker').off('click');
                $('span.marker').on ('click', function() {
                    var $marker = $(this),
                    $caption = $('div.caption', $marker);
                    $caption.slideToggle(300);
                });
            }
        },

        init: function() {
            this.fn.addMarkers();
        }
    },

    editMode: function() {

        if (EKCoord.edit_flag===2) {
            EKCoord.edit_flag = 0;
        } else {
            EKCoord.edit_flag++;
        }

        if (EKCoord.edit_flag===0) {
          $('#editmode').empty().html("View (M)ode On");
        } else if (EKCoord.edit_flag===1) {
          $('#editmode').empty().html("Edit (M)ode On");
        } else if (EKCoord.edit_flag===2) {
            $('#editmode').empty().html("Fast Edit (M)ode On");
        }
    },

    next: function () {

        EKCoord.unhighlightAndToggleCaption();

        EKCoord.current_marker_index++

        if (EKCoord.current_marker_index === EKCoord.rooms_data.length) {
            EKCoord.current_marker_index = 0;
        }
        $('#currentmarker').val(EKCoord.current_marker_index).change();
    },

    previous: function() {

        EKCoord.unhighlightAndToggleCaption();
        EKCoord.current_marker_index--

        if ( EKCoord.current_marker_index===(-1) ) {
            EKCoord.current_marker_index = EKCoord.rooms_data.length - 1;
        }
        $('#currentmarker').val(EKCoord.current_marker_index).change();
    },

    zoomIn: function() {

        EKCoord.zoom_level = EKCoord.zoom_level + 0.1;

        //Zoom level 100%
        if (EKCoord.zoom_level > 1) { EKCoord.zoom_level = 1; }

        $('#image-wrapper').css({
            width : $('#image-wrapper img').width (EKCoord.map_width  * EKCoord.zoom_level),
            height: $('#image-wrapper img').height(EKCoord.map_height * EKCoord.zoom_level)
        });

        $('#currentzoom').html( (EKCoord.zoom_level * 100).toString().split('.')[0] + '%');
        $(".marker").remove();
        EKCoord.Markers.init();
    },

    zoomOut: function() {

        EKCoord.zoom_level  = EKCoord.zoom_level - 0.1;

        $('#image-wrapper').css({
            width  : $('#image-wrapper img').width (EKCoord.map_width  * EKCoord.zoom_level),
            height : $('#image-wrapper img').height(EKCoord.map_height * EKCoord.zoom_level)
        });

        $('#currentzoom').html( (EKCoord.zoom_level * 100).toString().split('.')[0] + '%');
        $(".marker").remove();
        EKCoord.Markers.init();
    },

    setMapEditorKeyBindings: function() {

        $(document).bind('keyup', 'm', function() { EKCoord.editMode(); });

        $('#editmode').click(function (e) { EKCoord.editMode(); });

        $(document).bind('keyup', 't', function() { EKCoord.next(); });

        $(document).bind('keyup', 'right', function() { EKCoord.next(); });

        $('#next').click(function (e) { EKCoord.next(); });

        $('#currentmarker').change(function () {

            EKCoord.unhighlightAndToggleCaption();
            EKCoord.current_marker_index = $( "select option:selected" ).val();
            EKCoord.highlightCurrentMarker();
        });

        $(document).bind('keyup', 'r', function() { EKCoord.previous(); });

        $(document).bind('keyup', 'left', function() { EKCoord.previous(); });

        $('#previous').click(function (e) { EKCoord.previous(); });

        $(document).bind('keyup', 'x', function(){
            $(document).unbind('keyup');
            $("#map_editor").remove();
        });

        $('#exit').click(function (e) {
            $(document).unbind('keyup');
            $("#map_editor").remove();
        });

        $(document).bind('keyup', 'i', function() { EKCoord.zoomIn(); });

        $('#zoomin').click(function (e) { EKCoord.zoomIn(); });

        $(document).bind('keyup', 'o', function() { EKCoord.zoomOut(); });

        $('#zoomout').click(function (e) { EKCoord.zoomOut(); });
    },

    returnY: function(y) {
        return y + $("#map_editor").scrollTop() - (10 * EKCoord.zoom_level) - EKCoord.map_editor_offset.top - 5;//-10 for graphic, -5 for border
    },

    returnX: function(x) {
        return x + $("#map_editor").scrollLeft() - (10 * EKCoord.zoom_level) - EKCoord.map_editor_offset.left - 5;
    },

    returnActualX: function(x) {
        return ( ( x - EKCoord.map_editor_offset.left + $("#map_editor").scrollLeft () ) / EKCoord.zoom_level  ) - 5;
    },

    returnActualY: function(y) {
        return ( ( y - EKCoord.map_editor_offset.top  + $("#map_editor").scrollTop  () ) / EKCoord.zoom_level  ) - 5;
    },

    appendMarker: function(e) {
        $('<span class="marker"'                                                         +
                'id="marker-'                                                            +
                    EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id +
                '">'                                                                     +
            '</span>')
            .css({
                top    : EKCoord.returnY(e.pageY),
                left   : EKCoord.returnX(e.pageX),
                width  : 20 * EKCoord.zoom_level + "px",
                height : 20 * EKCoord.zoom_level + "px"
            })
            .html('<div class="caption">' + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.name + '</div>').appendTo( $('#image-wrapper') );
    },

    removeMarker: function() {
        $("[id='marker-" + EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id + "']").remove();
    },

    initializeClickToUpdate: function() {
        $('#image-wrapper').click(function (e) {
            if (EKCoord.edit_flag===1 || EKCoord.edit_flag===2) {

                EKCoord.removeMarker();
                EKCoord.appendMarker(e);
                EKCoord.Markers.fn.showCaptions();

                var newstatus   = [];
                var location_id = EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.id;

                newstatus.push({
                    location_id : location_id,
                    x           : EKCoord.returnActualX(e.pageX),
                    y           : EKCoord.returnActualY(e.pageY)
                });

                return $.ajax({
                    url  : "/room_coordinates_wizard/update_coordinate/" + EKCoord.event_id,
                    type : "PUT",
                    data : {
                        Coordinate: JSON.stringify(newstatus)
                    },
                    success: function() {
                        if (EKCoord.edit_flag===2) { EKCoord.next(); }
                        EKCoord.highlightCurrentMarker();
                        $('#option-' + location_id).css('background-color','#3D577E');
                    }
                });
            };
        });
    },

    startCoordinatesGui: function(location_mapping_order_number) {

        EKCoord.ekdebugger('startCoordinatesGui triggered');

        EKCoord.current_marker_index = location_mapping_order_number;
        var url                      = "/room_coordinates_wizard/ajax_map_image_path/" + EKCoord.map_id;

        $.getJSON(url, function (data) {

            EKCoord.appendMapEditor(data.event_map.path);
            EKCoord.map_editor_offset = $("#map_editor").offset();
            EKCoord.setMapWidthAndHeight();

            var rooms_url = "/room_coordinates_wizard/ajax_room_data/" + EKCoord.map_id;

            $.get(rooms_url, function (rooms_data) {
                EKCoord.rooms_data = rooms_data;
                EKCoord.addOptionElementsToGuiSelect();
                EKCoord.Markers.init();
                EKCoord.setMapEditorKeyBindings();
                EKCoord.initializeClickToUpdate();
            });
        });
    }
};


// not necessary in the success function?


// EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.x = x;
// EKCoord.rooms_data[EKCoord.current_marker_index].location_mapping.y = y;

// function add_event_listeners_to_location_mapping_show_buttons(event_id, map_id) {
//     EKCoord.$modalbody = $( "#room-modal-" + map_id + " > .modal-body" );
//     $(".locmapping").each(function() {
//         this.addEventListener("click", function() { startCoordinatesGui(event_id, map_id, EKCoord.$modalbody, this.id) });
//     });
// }




// abandoned (needs newer version of datatables)

//jump to page plug-in for datatables
// jQuery.fn.dataTableExt.oApi.jumpToData = function ( data, column ) {
//     var pos = this.column(column, {order:'current'}).data().indexOf( data );

//     if ( pos >= 0 ) {
//         var page = Math.floor( pos / this.page.info().length );
//         this.page( page ).draw( false );
//     }

//     return this;
// };

                    //.row.add //new version of datatables

//font awesome
// <i class="fa fa-flag markericon" style="font-size:' + (20 * EKCoord.zoom_level) + 'px;"></i>