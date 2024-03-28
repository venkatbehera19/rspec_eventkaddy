//handle multiple speaker rows
  $(function() {

    $('#session_files_summary').on('click','.multi_speaker_link',function(e) {
        //console.log("click trigger");

        e.preventDefault();

        //var session_file_id = $(e.currentTarget).children('.multi_speaker_session_file_id').text();
        var session_id = $(e.currentTarget).attr('href');//children('.multi_speaker_session_file_id').text();
        console.log(session_id);

        var filterF = function(item) { return ( item.toJSON().speaker.session_id=== parseInt(session_id) ); }
        var speakers = EK.speakerList.filter(filterF);

        var inner_html = '';

        for (var i=0;i<speakers.length;i++) {
            var speaker = speakers[i].toJSON().speaker;
            inner_html+= '<a href="/speakers/' + speaker.speaker_id + '">' + speaker.honor_prefix + ' ' + speaker.first_name + ' ' + speaker.last_name + ' ' + speaker.honor_suffix + '&lt;' + speaker.email + '&gt;</a><br/>'; 
            console.log(inner_html);
        }
        $('#lightbox').html('<p>' + inner_html + '</p>');

        $('#lightbox').show();
        $('#fade').show();

    });

    $('#fade').click(function(e) {
        
        $('#lightbox').hide();
        $('#fade').hide();
    });

      
   

  });

  