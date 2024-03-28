Eventkaddy::Application.routes.draw do

  get '/stats'           => 'statistics#stats'
  get '/session_by_room' => 'statistics#session_by_room'
  get '/tags'            => 'statistics#tags'

end