Eventkaddy::Application.routes.draw do

  get 'session_grid/xls_grid'

  get '/grid_view' => 'session_grid#grid_view'
  get '/session_grid/ajax_session_data'

  ## Autocomplete Links
  get 'session_grid/ajax_session_grid_autocomplete_data'
  get 'session_grid/ajax_session_grid_title_only_autocomplete_data'
  get 'session_grid/ajax_session_grid_speakers_only_autocomplete_data'
  get 'session_grid/ajax_session_grid_tags_only_autocomplete_data'
  get 'session_grid/ajax_session_grid_sponsors_only_autocomplete_data'

  ## Settings
  get 'session_grid/ajax_get_session_grid_settings'
  post 'session_grid/ajax_push_session_grid_settings'

end