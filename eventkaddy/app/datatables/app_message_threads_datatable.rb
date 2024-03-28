class AppMessageThreadsDatatable < Datatable

  def initialize params, event_id, view_context
    super params, event_id, view_context, AppMessageThread
  end

  private

  def record_count
    @record_count ||= AppMessageThread.where(event_id: event_id).count
  end

  # will be paginated by the parent class
  def data
    # the scary looking sum query here is to mitigate an issue with
    # the join query and group_by duplicating rows
    query = AppMessageThread
      .select(
        'app_message_threads.id, app_message_threads.title,
        SUM(
          attendees_app_message_threads.permanent_hide) / COUNT(attendees_app_message_threads.id) * COUNT(DISTINCT attendees_app_message_threads.id
        ) AS hidden,
        COUNT(DISTINCT attendees_app_message_threads.attendee_id) AS participants_count,
        GROUP_CONCAT( app_messages.content separator " | ") AS messages')
      .joins(:app_messages)
      .joins(:attendees_app_message_threads)
      .where(event_id:event_id)
      .order("#{sort_column} #{sort_direction}")
      .group('app_message_threads.id')
  end

  def sort_column
    %w[title messages permanent_hide][ iSortCol_0 ]
  end

  def search_query query
    query.where("app_message_threads.title LIKE :search OR app_messages.content LIKE :search", search: "%#{sSearch}%")
  end

  def datatable_row thread
      [
        thread.title,
        thread.messages,
        "#{thread.hidden ? thread.hidden.to_i : 0} / #{thread.participants_count}",
        view_context.link_to(
          'Show',
          "/app_message_threads/#{thread.id}",
          class: "btn show",
          style: "color:#178acc;border-color:#178acc;margin:auto;display:block; width:50%;"
        ), 
        view_context.link_to(
          'Hide',
          "/app_message_threads/hide/#{thread.id}",
          confirm: 'Are you sure?',
          method:  :post,
          class:   "btn delete",
          style:   "color:#A10000;border-color:#A10000;margin:auto;display:block; width:50%;"
        )
      ]
  end

end

# params = {"sEcho"=>"1", "iColumns"=>"5", "sColumns"=>"", "iDisplayStart"=>"0", "iDisplayLength"=>"10", "mDataProp_0"=>"0", "mDataProp_1"=>"1", "mDataProp_2"=>"2", "mDataProp_3"=>"3", "mDataProp_4"=>"4", "sSearch"=>"", "bRegex"=>"false", "sSearch_0"=>"", "bRegex_0"=>"false", "bSearchable_0"=>"true", "sSearch_1"=>"", "bRegex_1"=>"false", "bSearchable_1"=>"true", "sSearch_2"=>"", "bRegex_2"=>"false", "bSearchable_2"=>"true", "sSearch_3"=>"", "bRegex_3"=>"false", "bSearchable_3"=>"true", "sSearch_4"=>"", "bRegex_4"=>"false", "bSearchable_4"=>"true", "iSortCol_0"=>"0", "sSortDir_0"=>"asc", "iSortingCols"=>"1", "bSortable_0"=>"true", "bSortable_1"=>"true", "bSortable_2"=>"true", "bSortable_3"=>"false", "bSortable_4"=>"false", "_"=>"1513010811437"}
# view_context = Struct.new('ViewContext') do
#   def link_to label, url, args={}
#     label
#   end
# end.new
# AppMessageThreadsDatatable.new( params, 50, view_context).datatable_data
