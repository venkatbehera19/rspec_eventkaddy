class Datatable

  attr_reader :sEcho, :event_id, :ar_class, :iSortCol_0, :iDisplayLength, :iDisplayStart, :sSearch, :view_context, :sort_direction, :search_result

  def initialize params, event_id, view_context, ar_class
    @sEcho          = params[:sEcho].to_i
    @iDisplayLength = params[:iDisplayLength].to_i
    @iDisplayStart  = params[:iDisplayStart].to_i
    @sSearch        = params[:sSearch]
    @iSortCol_0     = params[:iSortCol_0].to_i
    @sort_direction = params[:sSortDir_0] == "desc" ? "DESC" : "ASC"
    @event_id       = event_id
    @ar_class       = ar_class
    @view_context   = view_context

    # should be overwritten by child classes
    @headers    = headers
    @source     = source
    @ao_columns = ao_columns
    @ao_column_defs = ao_column_defs
  end

  def headers
    []
  end

  def ao_columns
    []
  end

  def ao_column_defs
    []
  end

  def source
    ''
  end

  def datatable_data
    {
      sEcho:                sEcho,
      iTotalRecords:        record_count, # count of entries before search
      iTotalDisplayRecords: search.total_entries, # count of entries matching search
      aaData:               aaData
    }
  end

  def html
    template = ERB.new <<EOF
<table id="<%= ar_class.to_s %>" cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered">
    <thead>
        <tr>
            <% @headers.each do |h| %>
                <th><%= h %></th>
            <% end %>
        </tr>
    </thead>
    <tbody></tbody>
</table>

<script>
$(function() {
  $.extend($.fn.dataTableExt.oStdClasses, { "sWrapper": "dataTables_wrapper form-inline table-responsive" });

  $('#<%= ar_class.to_s %>').dataTable({
    "sDom": "<'pull-left'l><'ml-auto mr-1'f>rt<'pull-left'i><'ml-auto'p>",
    "bProcessing": true,
    "bServerSide": true,
    "sAjaxSource": "<%= @source %>",
    "aoColumns": <%= @ao_columns.to_json %>,
    "aoColumnDefs": <%= @ao_column_defs.to_json %>
  });
})
</script>
EOF
    template.result( binding ).html_safe
  end

  private

  def record_count
    @record_count ||= ar_class.where(event_id: event_id).count
  end

  def per_page
    iDisplayLength > 0 ? iDisplayLength : 10
  end

  def page
    iDisplayStart / per_page + 1
  end

  def search
    @search_result ||= begin
      query = data.page( page ).per_page( per_page )
      sSearch.present? ? search_query( query ) : query
    end
  end

  def aaData
    search.map &method(:datatable_row)
  end

  def data
    raise "This method should be overridden by a child class."
  end

  def search_query data
    raise "This method should be overridden by a child class."
  end

  def dataTableRow record
    raise "This method should be overridden by a child class."
  end

end
