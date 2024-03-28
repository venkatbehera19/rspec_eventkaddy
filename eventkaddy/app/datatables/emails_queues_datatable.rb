class EmailsQueuesDatatable < Datatable

  def initialize params, event_id, view_context
    super params, event_id, view_context, EmailsQueue
  end

  private

  def record_count
    @record_count ||= EmailsQueue.where(event_id: event_id).count
  end

  def source
    "/emails_queues/show_all"
  end

  def headers
    #readd, cancel
    ["Recipient Type", "Status", "Sent", "Email", ""]#, ""]
  end

  def ao_columns
    [
      { "sClass" => "emails_queues_recipient_type" },
      { "sClass" => "emails_queues_status" },
      { "sClass" => "emails_queues_sent" },
      { "sClass" => "emails_queues_email" },
      { "sClass" => "emails_queues_add_to_queue" },
      # { "sClass" => "emails_queues_cancel" }
    ]
  end

  def ao_column_defs
   [ { 'bSortable' => false, 'aTargets' => [4] } ]
  end

  def data
    query = EmailsQueue.
      select('emails_queues.id, status, sent, email, email_types.name AS type,
             CASE
             WHEN attendee_id THEN "attendee"
             WHEN speaker_id THEN "speaker"
             WHEN exhibitor_id THEN "exhibitor"
             WHEN exhibitor_staff_id THEN "exhibitor staff"
             WHEN user_id THEN "user"
             WHEN trackowner_id THEN "trackowner"
             END AS recipient_type').
      joins(:email_type).
      order("#{sort_column} #{sort_direction}").
      where(event_id:event_id)
  end

  def sort_column
    %w[recipient_type status sent email][ iSortCol_0 ]
  end

  def search_query query
    query.where("email LIKE :search OR status LIKE :search
                OR ('attendee' LIKE :search AND attendee_id IS NOT NULL)
                OR ('exhibitor' LIKE :search AND exhibitor_id IS NOT NULL)
                OR ('speaker' LIKE :search AND speaker_id IS NOT NULL)
                OR ('trackowner' LIKE :search AND trackowner_id IS NOT NULL)
                OR ('user' LIKE :search AND user_id IS NOT NULL)", search: "%#{sSearch}%")
  end

  def datatable_row email
    [
      email.recipient_type,
      email.status,
      email.sent,
      email.email,
      # This will need to be handled remotely instead... can I just remote:true?
      # Well, I can remote true, but actually I still need to give the user feedback
      # that they have successfully done something... so maybe I need some js here. too bad.
      # It might get annoying too, since the datatable elements may not be
      # available at the time of the binding.... maybe have to use onClick
        view_context.link_to(
          'Readd to Queue',
          "/emails_queues/readd_to_queue/#{email.id}",
          method:  :post,
          remote:  true,
          class:   "btn btn-outline-primary",
          onClick: add_to_queue_on_click(email),
          style:   "margin:auto;display:block;"
        )
        # cancel_button( email )
    ]
  end

  # def cancel_button email
  #   return "" unless email.status =='pending'
  #   view_context.link_to(
  #     'Cancel',
  #     "/emails_queues/cancel/#{email.id}",
  #     method:  :delete,
  #     remote:  true,
  #     class:   "btn delete",
  #     onClick: cancel_on_click(email),
  #     style:   "color:#A10000;border-color:#A10000;margin:auto;display:block; width:50%;"
  #   )
  # end

  def add_to_queue_on_click email
    <<EOF
(function(e) {
    $.post(
          "/emails_queues/readd_to_queue/#{email.id}",
          function(data) {
              if (data.status == true) {
                  console.log($(e).parent().parent().children('td')   )
                  $(e).parent().parent().children('td').css('background-color', '#B9F9C7')
                  $(e).parent().siblings('.emails_queues_status').html('pending')
                  $(e).parent().siblings('.emails_queues_sent').html('false')
                  $(e).parent().siblings('.emails_queues_add_to_queue').empty()
                  alert( 'Successfully readded to queue. Please note this page does not update as emails are sent out.' )
              } else {
                alert( JSON.stringify( data ) )
              }
          }
    ).fail(function() { alert('An error occured.'); })
})(this)
EOF
  end

  # this is probably just not that useful, since the table won't be staying in sync
  # def cancel_on_click email
  #   <<EOF
# $.post(
  #     "/emails_queues/readd_to_queue/#{email.id}",
  #     function(data) {
  #         alert( JSON.stringify( data ) )
  #     }
# ).fail(function() { alert('An error occured.'); })
# EOF
  # end

end
