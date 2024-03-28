class DevController < ApplicationController

  #RAILS4 TODO: before filter changes to before_action
  before_action :authorization_check
  layout 'subevent_2013'

  # fetch doc from jquery get on documenation page
  def document
    possible_documents = Dir.glob( Rails.root.join( 'documentation/**/*.org') ).
      map { |path| path.split('documentation/')[1] }
    if possible_documents.include? params[:path]
      render :plain => File.read( Rails.root.join("documentation/#{params[:path]}") ).
                        gsub('[[../../','[[https://github.com/somamedia/olympus/eventkaddy/'). # replace relative links with github links (good at least for ox branch, obviously not great for rabbit or other projects
                        gsub(Event.find(session[:event_id]).cms_url,'').html_safe # replace browser links with relative links
    else # don't let a user arbitrarily access files in our system
      render :plain => "#{params[:path]} does not lead to a valid document."
    end
  end

  def documentation
    def ensure_child name, ary
      r = ary.find {|k| k[name] }
      if r.is_a? Hash
        ary
      else
        ary << { name => [] }
        ary
      end
    end

    by_alphabetical = ->(a,b) {
      if a.has_key?(:name) && b.has_key?(:name)
        a[:name] <=> b[:name]
      elsif a.has_key?(:name)
        1
      elsif b.has_key?(:name)
        -1
      else
        a.keys[0] <=> b.keys[0]
      end
    }

    sort_recursive_by_alphabetical = ->(ary) {
      ary.sort! &by_alphabetical

      ary.each do |child|
        if child.values[0].is_a? Array
          sort_recursive_by_alphabetical.call child.values[0]
        end
      end
      ary
    }

    result = []

    # there may be a nice more elegant recursive way of doing this
    Dir.
      glob( Rails.root.join( 'documentation/**/*.org') ).
      map { |path| path.split('documentation/')[1].split('/') }.
      each do |path|

        current_level = result

        path.each_with_index do |part, index|
          if index == 0 && path.length > 1
            ensure_child part, result
            current_level = current_level.find {|k| k[ part ] }[part]
          elsif index < (path.length - 1)
            ensure_child part, current_level
            current_level = current_level.find {|k| k[ part ] }[part]
          else # last item
            first_line = File.open("documentation/"+path.join('/'), &:readline)
            if first_line.match /#\+TITLE:/
              pretty_name = first_line.split('TITLE:')[1]
            else
              pretty_name = false
            end
            current_level << { name: part, path: path.join('/'), pretty_name: pretty_name }
          end
        end
      end

    @documents = sort_recursive_by_alphabetical.call result
  end

  def dev
    @event_id = session[:event_id]
    @session_meta_data_job = BackgroundJob.where(entity_type: 'Event', entity_id: @event_id, purpose: 'add_session_meta_data').last
  end

  def events_summary
  end

  def update_event_dev_notes
    Event.find( params[:event][:id] ).update!( description: params[:event][:description] )
    redirect_to "/dev/events_summary"
  end

  def event_status
    @status = ReturnEventStatusObject.new(session[:event_id]).call
  end

  def event_tables
    @event_id = session[:event_id]
  end

  def action_history
    @action_histories = ActionHistory.
      select("action_histories.*, action_history_types.name AS type_name").
      where(event_id: 77 ).
      joins("LEFT JOIN action_history_types ON action_history_types.id = action_histories.action_history_type_id").
      order('updated_at DESC')
  end

  private

  def authorization_check
    authorize! :dev, :all
  end

end
