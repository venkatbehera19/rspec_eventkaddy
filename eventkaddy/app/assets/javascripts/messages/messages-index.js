modulejs.define('messages/messages-index', ['general_functions/ekaccordion'], function (Acc) {

    var MGI = {

        save_url: 'messages/reply',

        setAccordion: function() {
            Acc.init($('.clickable-title'));
        },

        addToolTips: function() {
            $('[data-toggle="tooltip"]').tooltip();
        },

        toggleThread: function(open_thread_button) {
            console.log("opening")
            $(open_thread_button).siblings('.hidden-message-form').slideToggle();
        },

        addSavedMessageToDOM: function(data) {

            var html, margin_left, reply_count, $messages;

            $messages   = $('#thread_' + data['message']['thread_id']).children('.messages-title-container');
            reply_count = $messages.length
            margin_left = reply_count < 6 ? 20*reply_count : 100;

            html =
                '<div style="margin-left:' + margin_left + 'px;" class="messages-title-container">' +
                    '<div class="messages-title-time pull-right">' +
                        'Sent on' +
                        data['message']['msg_time'] +
                    '</div>' +
                    '<div class="message-container">' +
                        '<div class="message-author">' +
                            data['message']['author'] +
                        '</div>' +
                        '<div class="message-content">' +
                            data['message']['content'] +
                        '</div>' +
                    '</div>' +
                '</div>';

            $messages.last().after(html);
        },

        success: function(data) {
            if (data["status"]) {
                MGI.addSavedMessageToDOM(data);
            } else {
                alert(data["error_messages"].join(' '));
            }
        },

        failure: function() {
            alert('An error occured and your message could not be sent.');
        },

        sendReply: function(submit_button) {

            $submit_button = $(submit_button);

            var thread_id = $submit_button.parent().siblings('.thread_id').val();
            var reply     = $submit_button.parent().siblings('.reply-field').children().val();

            $.post( MGI.save_url, { thread_id: thread_id, reply: reply }, function(data) {
                MGI.success(data);
                $submit_button.parent().siblings('.reply-field').children().val('')
            }).fail(function() { MGI.failure(); });
        },

        setSendReplyHandler: function() {
            MGI.$send_reply.on('click', function(e) { e.preventDefault(); MGI.sendReply(this); })
        },

        setThreadButtonsHandler: function() {
            MGI.$open_thread_buttons.on('click', function() { MGI.toggleThread(this); });
        },

        setHandlers: function() {

            MGI.setAccordion();
            MGI.addToolTips();
            MGI.setThreadButtonsHandler();
            MGI.setSendReplyHandler();
        },

        setVariables: function() {
            MGI.$open_thread_buttons = $('.thread-buttons span');
            MGI.$send_reply          = $('.send-reply');
        },

        init: function() {
            MGI.setVariables();
            MGI.setHandlers();
        }

    };
    return MGI;
});