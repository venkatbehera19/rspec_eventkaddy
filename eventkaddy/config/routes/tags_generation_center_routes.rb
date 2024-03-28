Eventkaddy::Application.routes.draw do

  get 'tags_generation_center' => 'tags_generation_center#tags_generation_center'

  put 'tags_generation_center/generate_date_tags'
  put 'tags_generation_center/generate_date_tags_without_a_top_tag'
  put 'tags_generation_center/remove_date_tags'
  put 'tags_generation_center/remove_date_tags_without_a_top_tag'

  put 'tags_generation_center/generate_session_location_tags'
  put 'tags_generation_center/generate_session_location_tags_without_a_top_tag'
  put 'tags_generation_center/remove_session_location_tags'
  put 'tags_generation_center/remove_session_location_tags_without_a_top_tag'

  put 'tags_generation_center/generate_exhibitor_location_tags'
  put 'tags_generation_center/generate_exhibitor_location_tags_without_a_top_tag'
  put 'tags_generation_center/remove_exhibitor_location_tags'
  put 'tags_generation_center/remove_exhibitor_location_tags_without_a_top_tag'

  patch 'tags_generation_center/generate_date_tags'
  patch 'tags_generation_center/generate_date_tags_without_a_top_tag'
  patch 'tags_generation_center/remove_date_tags'
  patch 'tags_generation_center/remove_date_tags_without_a_top_tag'

  patch 'tags_generation_center/generate_session_location_tags'
  patch 'tags_generation_center/generate_session_location_tags_without_a_top_tag'
  patch 'tags_generation_center/remove_session_location_tags'
  patch 'tags_generation_center/remove_session_location_tags_without_a_top_tag'

  patch 'tags_generation_center/generate_exhibitor_location_tags'
  patch 'tags_generation_center/generate_exhibitor_location_tags_without_a_top_tag'
  patch 'tags_generation_center/remove_exhibitor_location_tags'
  patch 'tags_generation_center/remove_exhibitor_location_tags_without_a_top_tag'
end