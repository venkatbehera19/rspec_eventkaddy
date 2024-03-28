Eventkaddy::Application.routes.draw do

  get 'dev' => 'dev#dev'

  get 'dev/event_status'
  get 'dev/event_tables'
  get 'dev/action_history'

end
