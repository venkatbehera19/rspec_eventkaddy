Eventkaddy::Application.routes.draw do

  get 'room_coordinates_wizard/ajax_array_of_all_location_mappings'

  get 'room_coordinates_wizard/ajax_room_data/:map_id' =>
    'room_coordinates_wizard#ajax_room_data'

  get 'room_coordinates_wizard/ajax_map_image_path/:map_id' =>
    'room_coordinates_wizard#ajax_map_image_path'

  delete 'room_coordinates_wizard/ajax_remove_room_map_id/:location_mapping_id' =>
    'room_coordinates_wizard#ajax_remove_room_map_id'

  put 'room_coordinates_wizard/update_coordinate/:event_id' => 'room_coordinates_wizard#update_coordinate'

  post 'room_coordinates_wizard/create_room' =>
    'room_coordinates_wizard#create_room'

end