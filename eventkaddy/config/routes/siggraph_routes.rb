Eventkaddy::Application.routes.draw do

  get 'siggraph_session_report' => 'siggraph#siggraph_session_report'

  get 'siggraph/generate_siggraph_rooms_schedules'

end