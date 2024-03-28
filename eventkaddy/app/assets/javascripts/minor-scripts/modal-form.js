var ModalForm = {

    returnNameOutput: function() {
        return '[' + this.$code_input.val() + '] ' + this.$name_input.val();
    },

    scrollToModalTop: function() {

        this.$modal_body.animate(
            {scrollTop: - this.$quick_add_successes_container[0].scrollHeight},
            500
        );
    },

    scrollSuccessInfoToBottom: function() {

        this.$quick_add_successes_container.animate(
            {scrollTop: this.$quick_add_successes_container[0].scrollHeight},
            1000
        );
    },

    clearInputs: function() {

        // Note: Clearing hidden time inputs will cause an issue
        // in subsequent submits. So only clear explictly
        // requested inputs.
        $.each($('.clear-on-submit'), function(i, element) { element.value = ''; } );
    },

    successOutput: function() {

        this.$quick_add_successes_container.append(
            '<br><span class="quick-add-success-name mr-3">' + this.returnNameOutput() + '</span>' +
            '<button type="button" data-url="/emails_queues/queue_email_password_for_attendee/' + this.$response_data.id + '" class="btn btn-link send-creds-trigger" data-method="post" style="font-size: 0.8rem;"><i class="fa fa-share-square"></i>Email Creds</button><span class="ml-1 status text-success"></span>'
        );
        $('.send-creds-trigger').on('click', function(){
            let elm = $(this);
            let statusElm = elm.next();
            $.post(elm.data('url'), null,
                function (data, textStatus, jqXHR) {
                    if (data.stats && data.stats === 'done'){
                        statusElm.html('<i class="fa fa-check"></i>')
                    }
                },
                "json"
            );
        });
    },

    success: function() {

        this.successOutput();
        this.clearInputs();
        this.scrollToModalTop();
        this.scrollSuccessInfoToBottom();
    },

    submitModalForm: function() {

        // this.$form.ajaxSubmit({
        //     success: function (data) { 
        //         ModalForm.success();
        //         console.log(data);
        //         this.$response_data = data;
        //     }
        // });
        for (instance in CKEDITOR.instances){
            CKEDITOR.instances[instance].updateElement();
        }
        $.ajax({
            type: this.$form.attr('method'),
            url: this.$form.attr('action'),
            data: new FormData(this.$form[0]),
            processData: false,
            contentType: false,
            dataType: 'json',
            success: function (response) {
                console.log(response);
                ModalForm.$response_data = response;
                ModalForm.success();
            }
        });
    },

    setHandlers: function() {

        $('#quick-add-submit').on('click', function(e) {
          e.preventDefault(); ModalForm.submitModalForm();
        });
    },

    init: function($form, $code_input, $name_input) {

        this.$form                          = $form;
        this.$code_input                    = $code_input;
        this.$name_input                    = $name_input;
        this.$quick_add_successes_container = $('#quick-add-successes');
        this.$modal_body                    = $('.modal-body');
        this.$response_data                 = null;


        this.setHandlers();
    }

};