require 'sidekiq/web'
Rails.application.routes.draw do

  # routes for app submission forms and uploads
  resources :app_submission_forms, except: [:new,:show,:destroy]
  resource :app_submission_form_uploads, only: [:show,:create] do
    get :download_zip, on: :member
  end


  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
  # mount Sidekiq::Web => "/sidekiq"
  authenticate :user, ->(user) { user.role?'SuperAdmin' } do
    mount Sidekiq::Web => "/sidekiq"
  end
  get '/surveys/copy_surveys_form' => 'surveys#copy_surveys_form'
  post '/surveys/copy_surveys_form' => 'surveys#post_copy_surveys_form'
  get '/surveys/survey_images' => 'surveys#survey_images'
  get '/surveys/download_attendee_survey_images' => 'surveys#download_attendee_survey_images'
  get '/surveys/attendee_survey_images' => 'surveys#attendee_survey_images'
  delete '/surveys/reset_attendee_survey_images' => 'surveys#reset_attendee_survey_images'
  get '/attendee_survey_images'                => 'attendee_survey_images#index'
  get '/attendee_survey_images/show'           => 'attendee_survey_images#show'
  get '/attendee_survey_images/download'       => 'attendee_survey_images#download'
  delete '/attendee_survey_images/reset'       => 'attendee_survey_images#reset'
  patch '/attendee_survey_images/verify_image' => 'attendee_survey_images#verify_image'
  patch '/attendee_survey_images/reject_image' => 'attendee_survey_images#reject_image'
  patch '/attendee_survey_images/undo_image'   => 'attendee_survey_images#undo_image_status'
  get '/settings/copy_settings_form' => 'settings#copy_settings_form'
  post '/settings/copy_settings_form' => 'settings#post_copy_settings_form'
  get '/exhibitor_portals/surveys'  => 'surveys#index'
  get '/exhibitor_portals/show_reports'  => 'exhibitor_portals#show_reports'
  get '/exhibitor_portals/reports/:attendee_id'  => 'exhibitor_portals#show_responses_per_attendee'
  get '/exhibitor_portals/video_visits'  => 'video_visits#index'
  get '/exhibitor_portals/video_visits/:attendee_id'  => 'video_visits#show'
  get '/exhibitor_portals/timeslot_bookings'  => 'slots#index'
  get '/reports/exhibitor_surveys_report/:exhibitor_id' => 'reports#exhibitor_surveys_report'
  get '/reports/video_visits_report/:exhibitor_id' => 'reports#video_visits_report'
  get '/reports/all_attendee_lead_report/:exhibitor_id' => 'reports#exhibitor_all_attendee_lead_report'

  draw :session_grid_routes
  draw :statistics_routes
  draw :ce_credits_routes
  draw :siggraph_routes
  draw :tags_generation_center_routes
  draw :forgot_password_routes
  draw :room_coordinates_wizard_routes


  # not all setting routes will be kept here anymore
  # search settings/ for other routes in this file
  # I've decided against this pattern of separating routes
  # as it doesn't work with rails autoloading (needs server restart every time)
  draw :settings_routes
  draw :survey_wizard_routes
  draw :dev_routes
  draw :surveys_api_routes
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'home#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  resources :slots
  resources :app_message_threads
  resources :app_badges
  # resources :attendees_app_badges
  resources :app_badge_tasks
  # resources :attendees_app_badge_tasks
  # resources :app_badge_task_types
  resources :app_games
  resources :scavenger_hunts
  resources :media_files
  resources :domains
  resources :polls
  resources :session_polls, :except => [:new,:create], :controller => "session_polls_cms"
  post '/session_polls/:id/restore'   => 'session_polls_cms#restore', as: :session_poll_restore
  delete '/session_polls/:id/session_poll_options/:session_poll_option_id'   => 'session_poll_options#destroy', as: :delete_session_poll_option

  post '/update_exhibitor_time_slot_status' => 'slots#update_exhibitor_time_slot_status'
  get 'slots/cancel/:id'                  => 'slots#cancel'
  delete 'polls/:id/options/:option_id'   => 'options#destroy'
  get 'polls/associations/:id'            => 'polls#associations'
  post 'polls/update_associations'       => 'polls#update_associations'
  get '/moderator_portals/sessions/:session_id/new_poll'  => 'polls#new_poll_by_moderator'
  get '/speaker_portals/sessions/:session_id/new_poll'  => 'speaker_portals#new_poll_by_speaker'

  get '/diff_event_settings/:event_id_a/:event_id_b' => 'events#diff_event_settings'

  get '/session_files/publish_select_sessions'
  post '/session_files/publish_session_files'

  get '/events_av_list_items/select'
  post '/events_av_list_items/update_select'
  post '/events_av_list_items/create'
  # resources :events_av_list_items
  # get '/events_av_list_items/index'
  # get '/events_av_list_items/new'
  # post '/events_av_list_items/create'

  get 'settings/speaker_email_password_template'
  get 'settings/exhibitor_email_password_template'
  get 'settings/attendee_email_password_template'
  get 'settings/attendee_email_confirmation_template'
  get 'settings/registration_attendee_email_password_template'
  get 'settings/registration_attendee_email_confirmation_template'
  get 'settings/registration_attendee_receipt_template'
  get 'settings/speaker_email_confirmation_template'
  get 'settings/calendar_invitation_email_template'
  get 'settings/ce_certificate_email_template'
  get 'settings/member_subscribe_email_template'
  get 'settings/member_unsubscribe_email_template'
  get 'settings/speaker_numeric_password_template'
  get 'settings/exhibitor_receipt_template'

  post 'settings/update_speaker_email_password_template'
  post 'settings/update_exhibitor_email_password_template'
  post 'settings/update_attendee_email_password_template'
  post 'settings/update_attendee_email_confirmation_template'
  post 'settings/update_registration_attendee_email_password_template'
  post 'settings/update_registration_attendee_email_confirmation_template'
  post 'settings/update_registration_attendee_receipt_template'
  post 'settings/update_speaker_email_confirmation_template'
  post 'settings/update_calendar_invitation_email_template'
  post 'settings/update_ce_certificate_email_template'
  get  "settings/get_email_template_image"
  get  "settings/get_email_template_image_organization"
  post 'settings/update_speaker_numeric_password_template'

  post 'settings/send_test_email'

  get 'settings/speaker_portal'
  get 'settings/speaker_portal/session_form'     => "settings#session_form"
  get 'settings/speaker_portal/other_tags'        => "settings#other_tags"
  get 'settings/speaker_portal/other_session_keywords' => "settings#other_session_keywords"
  post 'settings/update_speaker_portal_settings' => 'settings#update_speaker_portal_settings'
  post 'settings/update_speaker_portal_session_form' => 'settings#update_speaker_portal_session_form'

  get  '/reports/cordova_report'
  post '/reports/cordova_report'

  get  '/reports/iattend_scans_report'
  post '/reports/iattend_scans_report'

  get 'emails_queues/show_all'
  post 'emails_queues/queue_all_attendee_password_emails'
  post 'emails_queues/queue_all_speaker_password_emails'
  post 'emails_queues/queue_all_exhibitor_password_emails'
  post 'emails_queues/cancel_all'

  post 'emails_queues/readd_to_queue/:id'                             => 'emails_queues#readd_to_queue'
  post 'emails_queues/queue_email_password_for_attendee/:attendee_id' => 'emails_queues#queue_email_password_for_attendee'
  post 'emails_queues/queue_email_password_for_speaker/:speaker_id' => 'emails_queues#queue_email_password_for_speaker'
  post 'emails_queues/queue_email_password_for_exhibitor/:exhibitor_id' => 'emails_queues#queue_email_password_for_exhibitor'
  post 'emails_queues/queue_exhibitor_staff_password_email/:exhibitor_staff_id' => 'emails_queues#queue_exhibitor_staff_password_email'
  delete 'emails_queues/cancel/:id'                                   => 'emails_queues#cancel'

  get 'settings/admin_cordova'
  post 'settings/update_admin_cordova_settings' => 'settings#update_admin_cordova_settings'

  post 'events/upload_mobile_css' => 'events#upload_mobile_css'
  get 'reports/download_exhibitors'
  post 'reports/download_exhibitors'

  get 'reports/download_speakers'
  post 'reports/download_speakers'

  get 'reports/download_attendees'
  post 'reports/download_attendees'
  post 'reports/download_members'

  get 'surveys/exhibitor_associations/:id' => 'surveys#exhibitor_associations'
  patch 'surveys/update_exhibitor_associations' => 'surveys#update_exhibitor_associations'

  get 'surveys/ce_certificate_associations/:id' => 'surveys#ce_certificate_associations'
  patch 'surveys/update_ce_certificate_associations' => 'surveys#update_ce_certificate_associations'

  get 'reports/basic_session_favourite_info/:event_id/:date' => 'reports#basic_session_favourite_info'

  post 'events/download_sessions_async' => 'events#download_sessions_async'
  post 'events/download_sessions_full_async' => 'events#download_sessions_full_async'

  get 'dev/documentation'
  get 'dev/document'

  get 'events/change_reports'
  get 'events/attendee_checked_in'

  get 'dev/events_summary'
  patch 'dev/update_event_dev_notes'

  get 'app_games/:id/export_xlsx' => "app_games#export_xlsx"

  get 'settings/guest_view'
  post 'settings/update_guest_view_settings' => 'settings#update_guest_view_settings'

  get "reports/all_badges_completed_leaderboard_report"
  post "reports/all_badges_completed_leaderboard_report"

  get "reports/avma_program_grid/:event_id" => "reports#avma_program_grid"

  get "reports/exhibitor_attendee_report"
  post "reports/exhibitor_attendee_report"

  get "reports/exhibitor_user_summary_report"
  post "reports/exhibitor_user_summary_report"

  get "reports/event_177_scan_report"
  get "reports/flare_photos_report"
  post "reports/flare_photos_report"

  get "reports/exhibitor_leads_report"
  post "reports/exhibitor_leads_report"

  get "reports/exhibitors_scan_report"
  post "reports/exhibitors_scan_report"

  # get "reports/exhibitor_surveys_report/:exhibitor_id"

  get "reports/iattend_scans_by_attendee_report"
  post "reports/iattend_scans_by_attendee_report"

  get "reports/iattend_scans_by_attendee_report_v2"
  post "reports/iattend_scans_by_attendee_report_v2"

  get "leaderboard_for_projector/:event_id" => "app_games#leaderboard_for_projector"
  get "leaderboard_for_projector_for_full_completion/:event_id" => "app_games#leaderboard_for_projector_for_full_completion"

  get "notifications/hidden_notification"
  post "notifications/create_hidden_notification"

  post "moderator_portals/update_question_text/:id"            => "moderator_portals#update_question_text"
  post "moderator_portals/update_answer_text/:id"              => "moderator_portals#update_answer_text"
  post "moderator_portals/mark_question_answered/:id"          => "moderator_portals#mark_question_answered"
  post "moderator_portals/whitelist_question/:id"              => "moderator_portals#whitelist_question"
  post "moderator_portals/revoke_whitelist_question/:id"       => "moderator_portals#revoke_whitelist_question"
  post "moderator_portals/post_qa"                             => "moderator_portals#post_qa"
  delete "moderator_portals/delete_question/:id"               => "moderator_portals#delete_question"
  get '/moderator_portals/session_video/:id'                   => 'moderator_portals#session_video'
  get '/moderator_portals/sessions/:session_id/session_polls'  => 'session_polls#index'
  post '/moderator_portals/update_session_poll_status'         => 'session_polls#update_session_poll_status'
  post '/moderator_portals/session_polls/:id/restore'          => 'session_polls#restore',as: :moderator_session_poll_restore
  get '/moderator_portals/session_polls/:id'                   => 'session_polls#show',as: :moderator_session_poll
  get '/moderator_portals/session_polls/:id/edit'              => 'session_polls#edit',as: :edit_moderator_session_poll
  patch '/moderator_portals/session_polls/:id'                 => 'session_polls#update',as: :update_moderator_session_poll
  post '/moderator_portals/session_polls/:id/remove'           => 'session_polls#remove',as: :moderator_session_poll_remove
  post '/moderator_portals/session_polls/add_polls'            => 'session_polls#add_polls'
  post "app_message_threads/hide/:id"                          => "app_message_threads#hide"
  post "app_message_threads/unhide/:id"                        => "app_message_threads#unhide"
  delete '/moderator_portals/session_polls/:id/session_poll_options/:session_poll_options' => "session_polls#destroy"

  # if needed I can make a special route for avma to avoid editing the cordova app
  get "daily_quote/:event_id" => "guest_views#daily_quote"

  get "qa_feed/:session_id" => "guest_views#qa_feed"
  post "qa_ajax_data/:session_id" => "guest_views#qa_ajax_data"

  post 'idem_remote_sign_in' => 'users#remote_sign_in'

  get 'exhibitor_portals/product_preview' => 'exhibitor_portals#product_preview'
  get 'exhibitor_portals/page_settings' => 'exhibitor_portals#page_settings'
  post 'exhibitor_portals/update_page_settings' => 'exhibitor_portals#update_page_settings'
  get 'exhibitor_portals/edit_tags' => 'exhibitor_portals#edit_tags'
  # it getes the route even though we don't need it, because I don't want to redesign tags/update_tags
  post 'exhibitor_portals/update_tags/:tag_type_name/:model_id' => 'exhibitor_portals#update_tags'
  get '/exhibitor_portals/mobile_app_preview' => 'exhibitor_portals#mobile_app_preview'
  get '/exhibitor_portals/mobile_app_content' => 'exhibitor_portals#mobile_app_content'

  get 'tags/edit_tags/:tag_type_name/:model_id' => 'tags#edit_tags'
  post 'tags/update_tags/:tag_type_name/:model_id' => 'tags#update_tags'

  # hide in cordova app
  get 'events/hide_in_app_events'
  post 'events/update_hide_in_app_events'

  # hide in admin listing on cms
  get 'events/hidden_events'
  post 'events/update_hidden_events'

  get 'events/edit_preset_tag_options'
  post 'events/update_preset_tag_options'
  post '/events/add_preset_tags/:tag_id'  => "events#add_preset_tags"
  post '/events/remove_preset_tags/:tag_id' => "events#remove_preset_tags"
  post '/events/add_preset_keywords/:keyword_id' => "events#add_preset_keywords"
  post '/events/remove_preset_keywords/:keyword_id' => "events#remove_preset_keywords"

  get 'events/edit_type_to_pn_hash'
  post 'events/update_type_to_pn_hash'

  get 'events/download_generated_certificates_as_zip'

  get '/sessions_attendees/multiple_new_for_all'
  post '/sessions_attendees/update_multiple_new_for_all'


  get '/exhibitors/booth_owners_list/:event_id' => 'exhibitors#booth_owners_list'

  get '/events/download_logins'   => 'reports#download_logins'
  get '/reports/download_logins'  => 'reports#download_logins'
  post '/reports/download_logins' => 'reports#download_logins'

  get '/reports/download_reporting_logins'  => 'reports#download_reporting_logins'
  post '/reports/download_reporting_logins'  => 'reports#download_reporting_logins'

  post 'attendees/bulk_set_attendees_photos_to_online'
  post 'speakers/bulk_set_speakers_photos_to_online'
  post 'exhibitors/bulk_set_exhibitors_photos_to_online'

  get "partner_portals/landing"

  get 'events/edit_event_settings'
  post 'events/update_event_settings'
  get 'events/statistics_pdf'
  get 'events/game_statistics'
  get 'events/statistics'
  get 'events/report_downloads'
  get 'tags/abandoned_tags'

  resources :tags

  post 'sessions_speakers/toggle_unpublished/:id' => 'sessions_speakers#toggle_unpublished'

  post 'events/avma_regenerate_attendee_tags'
  post 'custom_adjustments/session_file_urls_to_secure_field'               => 'custom_adjustments#session_file_urls_to_secure_field'
  post 'custom_adjustments/add_automated_notification_filters_to_attendees'               => 'custom_adjustments#add_automated_notification_filters_to_attendees'
  post 'custom_adjustments/update_attendee_passwords_for_event'               => 'custom_adjustments#update_attendee_passwords_for_event'
  post 'custom_adjustments/remove_all_speakers_and_associations'                          => 'custom_adjustments#remove_all_speakers_and_associations'
  post 'custom_adjustments/remove_all_sessions_without_video_urls_and_abandoned_speakers' => 'custom_adjustments#remove_all_sessions_without_video_urls_and_abandoned_speakers'
  post 'custom_adjustments/remove_all_speakers_without_sessions_and_associations'         => 'custom_adjustments#remove_all_speakers_without_sessions_and_associations'
  post 'custom_adjustments/remove_all_session_files'                                      => 'custom_adjustments#remove_all_session_files'
  post 'custom_adjustments/add_track_subtracks_to_sessions'                               => 'custom_adjustments#add_track_subtracks_to_sessions'
  post 'custom_adjustments/add_speaker_names_to_sessions'                                 => 'custom_adjustments#add_speaker_names_to_sessions'
  post 'custom_adjustments/add_speaker_names_to_sessions_new'                                 => 'custom_adjustments#add_speaker_names_to_sessions_new'
  get 'custom_adjustments/get_video_url_for_one_session/:session_id' => 'custom_adjustments#get_video_url_for_one_session'
  get 'custom_adjustments/encode_video_for_one_session/:session_id' => 'custom_adjustments#encode_video_for_one_session'
  get 'custom_adjustments/search_for_encoded_video/:session_id' => 'custom_adjustments#search_for_encoded_video'
  get 'custom_adjustments/create_thumbnail_for_one_session/:session_id' => 'custom_adjustments#create_thumbnail_for_one_session'
  post '/custom_adjustments/add_meta_data_to_tags' => 'custom_adjustments#add_meta_data_to_tags'
  get '/custom_adjustments/meta_data_job_status' => 'custom_adjustments#meta_data_job_status'

  post 'location_mappings/remove_association/:id' => 'location_mappings#remove_association'

  get '/sessions/bulk_add_session_thumbnails'
  post '/sessions/bulk_create_session_thumbnails'

  get '/sessions/select_pdf_date'       => 'sessions#select_pdf_date'
  get '/sessions/list_pdfs'             => 'sessions#list_pdfs'
  post '/sessions/bulk_update_publish_pdf_field' => 'sessions#bulk_update_publish_pdf_field'


  get '/attendees/bulk_add_attendee_photos'
  post '/attendees/bulk_create_attendee_photos'

  get '/reports/attendees_who_completed_surveys_report'
  get '/reports/global_survey_report'
  get '/reports/daily_health_check_report' => 'reports#daily_health_check_report'
  post '/reports/daily_health_check_unsubmitted_attendees_report' => 'reports#daily_health_check_unsubmitted_attendees_report'
  post '/reports/generate_session_survey_reports'

  get '/reports/attendee_survey_report'

  get '/reports/general_survey_report'
  post '/reports/general_survey_report'

  get '/reports/general_survey_report_simple'
  post '/reports/general_survey_report_simple'

  get '/reports/quiz_survey_report'
  post '/reports/quiz_survey_report'

  get '/reports/attendee_scans_summary_report'
  post '/reports/attendee_scans_summary_report'

  get '/reports/attendee_scans_full_report'
  post '/reports/attendee_scans_full_report'

  get 'job_status' => 'jobs#job_status'
  post 'create_job' => 'jobs#create_job'
  post 'cancel_jobs' => 'jobs#cancel_jobs'

  get 'game_results' => 'game_results#game_results'
  get 'download_game_results' => 'game_results#download_game_results'

  #get 'scavenger_hunt_items' => 'scavenger_hunt_items#index'
  post 'scavenger_hunt_items' => 'scavenger_hunt_items#create'
  patch 'scavenger_hunt_items/:id' => 'scavenger_hunt_items#update'
  put 'scavenger_hunt_items/:id' => 'scavenger_hunt_items#update'
  delete 'scavenger_hunt_items/:id' => 'scavenger_hunt_items#destroy'

  delete 'attendees/destroy_game_and_survey_data_for_attendee/:id' => 'attendees#destroy_game_and_survey_data_for_attendee'
  delete 'attendees/delete_all_demo_attendees_game_and_survey_data' => 'attendees#delete_all_demo_attendees_game_and_survey_data'

  delete 'attendees/delete_all_iattend_data' => 'attendees#delete_all_iattend_data'
  delete 'attendees/delete_all_recommendations' => 'attendees#delete_all_recommendations'
  get 'attendees/daily_checkup_attendees' => 'attendees#daily_checkup_attendees'
  get 'attendees/get_survey_responses' => 'attendees#get_survey_responses'

  delete 'events/delete_abandoned_tags' => 'events#delete_abandoned_tags'

  delete 'surveys/:id' => 'surveys#destroy'

  #app images
  get '/app_images/select_type'                         => 'app_images#select_type'
  post '/app_images/generate_banners'
  put '/app_images/update_banners'#/:id' => 'app_images#update_banners'
  post '/app_images/list_templates'                     => 'app_images#list_templates'
  post '/app_images/fetch_sized_image_url'              => 'app_images#fetch_sized_image_url'
  get '/app_images', :controller => 'app_images', :action => 'options', :constraints => {:method => 'OPTIONS'}

  get 'event_settings/banners'

  # cheeky redirect to avoid modifying how event_tabs works for exhibitor_portal
  # (always adds exhibitor_portals/ to front of url)
  get 'exhibitor_portals/exhibitor_products'        => 'exhibitor_products#index'
  get 'exhibitors/exhibitor_products/:exhibitor_id' => 'exhibitor_products#index'

  get 'exhibitor_products/exhibitor_products_report' => 'reports#exhibitor_products_report'
  get 'reports/exhibitor_products_report'            => 'reports#exhibitor_products_report'
  post 'reports/exhibitor_products_report'           => 'reports#exhibitor_products_report'

  post '/attendees/mailers/generate_ce_sessions_pdf_report' => 'attendees#generate_ce_sessions_pdf_report'
  post '/attendees/mailers/generate_lead_surveys_report'    => 'attendees#generate_lead_surveys_report'
  get '/attendees', :controller => 'attendees', :action => 'options', :constraints => {:method => 'OPTIONS'}
  post '/notes/sync/set_email'                              => 'attendees#email_attendee_notes'


  get 'events/show_gallery_photos'                => 'events#show_gallery_photos'
  put 'events/upload_gallery_photos'              => 'events#upload_gallery_photos'
  get 'events/gallery_photos_json_data/:event_id' => 'events#gallery_photos_json_data'

  put 'home_buttons/reset_buttons'
  put 'home_buttons/:id/disable_home_button' => 'home_buttons#disable_home_button'
  put 'home_buttons/:id/enable_home_button'  => 'home_buttons#enable_home_button'

  get 'custom_list_items/new/:custom_list_id' => 'custom_list_items#new'
  get 'custom_list_items/ajax_data'           => 'custom_list_items#ajax_data'

  get "speaker_portals/downloads/:file_id" => 'speaker_portals#download'

  get "reports/sessionsreview" => 'reports#sessions_review'
  get "reports/video_portal_report"
  get "reports/video_portal_survey_report"
  get 'reports/session_survey_report'

  get "room_layouts/:session_id/session_links" => 'room_layouts#session_links'
  post "room_layouts/create_session_link" => 'room_layouts#create_session_link'
  delete '/room_layouts/:session_id/remove_session_link/:room_layout_id' => 'room_layouts#remove_session_link'

  get "session_av_requirements/:session_id/new" => 'session_av_requirements#new'
  get "session_av_requirements/:session_id/new_laptop" => 'session_av_requirements#new_laptop'
  post "session_av_requirements/:session_id/create_laptop" => 'session_av_requirements#create_laptop'
  get "session_av_requirements/:session_id/index" => 'session_av_requirements#index'

  get "messages/ajax_data" => 'messages#ajax_data'
  get "home_button_entries/ajax_data" => 'home_button_entries#ajax_data'

  get "session_files/summary" => 'session_files#summary'
  get "session_files/select_sessions" => 'session_files#select_sessions'
  post "session_files/update_select_sessions" => 'session_files#update_select_sessions'

  get "session_files/spreadsheet_summary"              => 'reports#session_files_summary_conference_note'
  get  "reports/session_files_summary_conference_note" => 'reports#session_files_summary_conference_note'
  post "reports/session_files_summary_conference_note" => 'reports#session_files_summary_conference_note'

  get "session_files/add_file_to_all" => 'session_files#add_file_to_all'
  get "session_files/finalize_versions" => 'session_files#finalize_versions'
  get "session_files/download_all_zip" => "session_files#download_all_zip"

  get "session_files/:session_id/index" => 'session_files#index'
  get "session_files/:session_id/new" => 'session_files#new'
  get "session_files/show"
  get "session_files/create"
  get "session_files/edit"
  get "session_files/update"
  get "session_files/delete"

  get "speaker_files/:speaker_id/index" => 'speaker_files#index'
  get "speaker_files/:speaker_id/new/:original_document_id" => 'speaker_files#new'
  get "speaker_files/show"
  get "speaker_files/create"
  get "speaker_files/edit"
  get "speaker_files/update"
  get "speaker_files/delete"


  get "session_file_versions/:session_file_id/index" => 'session_file_versions#index'
  get "session_file_versions/:session_file_id/new" => 'session_file_versions#new'
  get "session_file_versions/show"
  get "session_file_versions/create"
  get "session_file_versions/edit"
  get "session_file_versions/update"
  get "session_file_versions/delete"

  get "trackowner_portals/landing"
  get "trackowner_portals/sessions"
  get "trackowner_portals/speakers"
  get "trackowner_portals/speaker_files_zip"
  get "trackowner_portals/session_files"
  get "trackowner_portals/session_files_zip"
  get "trackowner_portals/edit_account"
  put "trackowner_portals/update_account"


  get "speaker_portals/sign_in"
  get "speaker_portals/home"
  get "speaker_portals/help"
  get "speaker_portals/checklist"
  get "speaker_portals/show_contactinfo"
  get "speaker_portals/edit_account"
  put "speaker_portals/update_account"
  patch "speaker_portals/update_contactinfo"  => "speaker_portals#update_contactinfo"


  get "attendee_portals/edit_account"
  put "attendee_portals/update_account"
  get "attendee_portals/landing/:slug" => 'attendee_portals#landing'
  get "attendee_portals/profile" => 'attendee_portals#profile'
  get 'attendee_portals/edit_profile' => "attendee_portals#edit_profile"
  put 'attendee_portals/update_profile'     => "attendee_portals#update_profile"
  get 'attendee_portals/edit_survey'   =>  "attendee_portals#edit_survey"
  put 'attendee_portals/update_survey' =>  "attendee_portals#update_survey"
  get '/attendee_portals/my_orders'   => "attendee_portals#my_orders"
  get "attendee_portals/download_invoice/:transaction_id" => 'attendee_portals#download_invoice'
  delete 'attendee_portals/logout', to: 'attendee_portals#logout_attendee', as: :attendee_logout
  get 'attendee_portals/product/:slug' => "attendee_portals#product"
  get '/:event_id/attendee_portals/cart/:id'  => "attendee_portals#cart"
  put '/:event_id/attendee/update_cart/:id'   => "attendee_portals#update_cart"
  get '/:event_id/attendee/payment/:id'       => "attendee_portals#attendee_payment"
  post '/orders/stripe/payment_attendee'  => 'attendee_portals#stripe_create_payment', as: :stripe_payment_attendee_portal
  get '/orders/stripe/complete_payment_attendee' => 'attendee_portals#stripe_complete_payment_attendee'
  get '/attendee_portals/:user_id/payment_success' => "attendee_portals#payment_success"
  delete  '/:event_id/attendee/delete_item/:cart_id'   => "attendee_portals#delete_item"

  resources :products do
    member do
      post 'add'
      post 'add_product_stripe'
      get  'success'
      get  'refunded'
    end
    collection do
      get 'unorder'
    end
  end

  # attendee_portal payment
  namespace :attendees do
    resources :products, only: [:index]
    resources :cart_items, only: [:index, :update, :destroy]
    resources :orders, only: [:index, :create, :update] do
      resources :payments, only: [:new, :create] do
        get :confirm_payment, on: :collection
      end
    end
  end

  namespace :exhibitors do
    resources :cart_items, only: [:update, :destroy]
  end

  namespace :exhibitor_portals do
    resources :cart_items, only: [:update, :destroy]
  end

  resources :orders, only: [:destroy]

  get "exhibitor_portals/landing"
  get "exhibitor_portals/show_exhibitordetails"
  put "exhibitor_portals/update_exhibitordetails"
  patch "exhibitor_portals/update_exhibitordetails"
  get "exhibitor_portals/messages" => 'exhibitor_messages#messages'
  get "exhibitor_portals/edit_account"
  put "exhibitor_portals/update_account"
  get "exhibitor_portals/show_message"
  get "exhibitor_portals/edit_custom_content"
  put "exhibitor_portals/update_custom_content"
  patch "exhibitor_portals/update_custom_content"
  get "exhibitor_portals/ajax_data"
  get "exhibitor_portals/exhibitor_files"
  get "exhibitors/edit_custom_content/:exhibitor_id" => "exhibitor_portals#edit_custom_content"
  get "exhibitor_portals/exhibitor_stickers" => "exhibitor_portals#exhibitor_stickers"
  post "exhibitor_portals/create_sticker" => "exhibitor_portals#create_sticker"
  delete "exhibitor_portals/delete_sticker/:sticker_id" => "exhibitor_portals#delete_sticker"
  post "exhibitor_portals/reposition_stickers" => "exhibitor_portals#reposition_stickers"
  post 'exhibitor_portals/update_sticker/:sticker_id' => 'exhibitor_portals#update_sticker'
  post 'exhibitor_portals/update_sticker_fixed_status' => 'exhibitor_portals#update_sticker_fixed_status'
  get "exhibitor_portals/my_orders" => 'exhibitor_portals#my_orders'
  get "exhibitor_portals/download_invoice/:transaction_id" => 'exhibitor_portals#download_invoice'

  get "exhibitor_portals/products" => 'exhibitor_portals#products'
  get '/:event_id/exhibitor_portals/transactions/payment/:cart_id' => 'exhibitor_portals#exhibitor_payment'
  get '/:event_id/exhibitor_portals/cart/:cart_id' => 'exhibitor_portals#cart'
  get    "exhibitor_portals/index_pdf"
  get    "/exhibitor_portals/new_pdf"
  post   "exhibitor_portals/create_pdf"
  get    "exhibitor_portals/edit_pdf/:id" => 'exhibitor_portals#edit_pdf'
  patch  "exhibitor_portals/update_pdf/:id" => 'exhibitor_portals#update_pdf'
  delete "exhibitor_portals/delete_pdf/:id" => 'exhibitor_portals#delete_pdf'
  get    "exhibitor_portals/download_pdf"
  get    "/exhibitor_portals/new_file"
  post   "exhibitor_portals/create_file"
  get    "exhibitor_portals/edit_file/:id" => 'exhibitor_portals#edit_file'
  patch  "exhibitor_portals/update_file/:id" => 'exhibitor_portals#update_file'
  get    "exhibitor_portals/files"   => "exhibitor_portals#files"

  # exhibitor_zero_total_payment
  ## Exhibitor Messages

  # get 'exhibitor_messages'         => 'exhibitor_messages#messages'
  get 'exhibitor_messages/new'           => 'exhibitor_messages#new'
  get 'exhibitor_messages/settings'      => 'exhibitor_messages#settings'
  patch 'exhibitor_messages/settings'    => 'exhibitor_messages#settings_update'
  post 'exhibitor_messages/create'       => 'exhibitor_messages#create'
  post 'exhibitor_portals/messages/reply'=> 'exhibitor_messages#reply'
  get 'exhibitor_messages/markread/:id'  => 'exhibitor_messages#markread'
  get 'ajax_attendees_array'             => 'exhibitor_messages#ajax_attendees_array'
  get 'exhibitor_messages/inaccessible'
  get 'exhibitor_staffs/add_booth_owner/:id' => 'exhibitor_staffs#associate_attendee_account'
  delete 'exhibitor_staffs/remove_booth_owner/:id' => 'exhibitor_staffs#remove_booth_owner'
  get '/check_existing_email' => 'exhibitor_staffs#check_existing_email'

  get "moderator_portals/landing"
  get "moderator_portals/sessions" => 'moderator_portals#sessions'
  get "moderator_portals/qa_feed/:session_id" => "moderator_portals#qa_feed"
  post "moderator_portals/qa_ajax_data/:session_id" => "moderator_portals#qa_ajax_data"

  get "speaker_portals/show_travel_detail"
  get "speaker_portals/print_view"

  get "speaker_portals/sessions/:speaker_type" => 'speaker_portals#sessions'
  get "speaker_portals/sessions" => 'speaker_portals#sessions'
  get "speaker_portals/session_detail/:session_id" => 'speaker_portals#session_detail'

  get "speaker_portals/show_payment_detail"
  put "speaker_portals/update_payment_detail"
  post "speaker_portals/update_payment_detail"
  get "speaker_portals/messages"
  # get "speaker_portals/favourite_exhibitors"
  # get "speaker_portals/show_favourite_exhibitor/:id"

  get "speaker_portals/index_pdf"
  get "speaker_portals/new_pdf"
  post "speaker_portals/create_pdf"
  get "speaker_portals/edit_pdf/:id" => 'speaker_portals#edit_pdf'
  patch "speaker_portals/update_pdf/:id" => 'speaker_portals#update_pdf'
  put "speaker_portals/update_pdf/:id" => 'speaker_portals#update_pdf'
  delete "speaker_portals/delete_pdf/:id" => 'speaker_portals#delete_pdf'
  get "speaker_portals/download_pdf"

  get "speaker_portals/edit_email"
  put "speaker_portals/update_email"

  patch "speaker_portals/update_session/:id" => 'speaker_portals#update_session'
  get "speaker_portals/edit_session/:id" => 'speaker_portals#edit_session'

  get "speaker_portals/faq"
  get "speaker_portals/session_polls"
  get "speaker_portals/session_polls_list/:session_id" => 'speaker_portals#session_polls_list'
  resources :speaker_portals, only: [ :new, :create, :edit, :update, :show]

  get '/sessions/:id/session_speakers' => 'sessions#session_speakers'
  post '/sessions/:id/add_session_speaker' => 'sessions#add_session_speaker'
  delete '/sessions/:id/remove_session_speaker/:speaker_id' => 'sessions#remove_session_speaker'

  get '/sessions/:id/session_sponsors' => 'sessions#session_sponsors'
  post '/sessions/:id/add_session_sponsor' => 'sessions#add_session_sponsor'
  delete '/sessions/:id/remove_session_sponsor/:sponsor_id' => 'sessions#remove_session_sponsor'


  get '/sessions/tags_autocomplete' => 'sessions#tags_autocomplete'
  get '/sessions/:id/:tag_type_name/session_tags' => 'sessions#session_tags'
  post '/sessions/:id/update_session_tags' => 'sessions#update_session_tags'

  get '/events/add_files_to_placeholders' => 'events#add_files_to_placeholders'
  # get '/events/create_files_for_placeholders' => 'events#create_files_for_placeholders'
  post '/events/create_files_for_placeholders' => 'events#create_files_for_placeholders'

  get '/attendees/tags_autocomplete'                => 'attendees#tags_autocomplete'
  get '/attendees/:id/:tag_type_name/attendee_tags' => 'attendees#attendee_tags'
  post '/attendees/:id/update_attendee_tags'        => 'attendees#update_attendee_tags'
  get '/attendees/:id/view_history'                 => 'attendees#view_history'
  get '/attendees/:id/view_history/video_views/:v_id'     => 'attendees#show_video_views'
  get '/attendees/:id/view_history/page_views/:p_id'      => 'attendees#show_page_views'
  # attendee history reports
  get '/attendees/:id/ce_sessions_report'                 => 'attendees#ce_sessions_report'
  get '/attendees/:id/favorited_exhibitors_report'        => 'attendees#favorited_exhibitors_report'
  get '/attendees/:id/page_view_exhibitors_report'        => 'attendees#page_view_exhibitors_report'
  get '/attendees/:id/page_view_sessions_report'          => 'attendees#page_view_sessions_report'
  get '/attendees/:id/video_views_report'                 => 'attendees#video_views_report'
  get '/attendees/:id/platform_logins_report'             => 'attendees#platform_logins_report'
  get '/filtered_attendee_list'     => 'attendees#filtered_attendee_list'
  get '/search_and_paginate_filtered_attendees' => 'attendees#search_and_paginate_filtered_attendees'
  get '/attendees/purchased' => "attendees#purchased"

  get '/exhibitors/tags_autocomplete' => 'exhibitors#tags_autocomplete'
  get '/exhibitors/:id/:tag_type_name/exhibitor_tags' => 'exhibitors#exhibitor_tags'
  post '/exhibitors/:id/update_exhibitor_tags' => 'exhibitors#update_exhibitor_tags'
  get  "exhibitors/files/:exhibitor_id" => "exhibitors#files"


  get "exhibitor_files/:exhibitor_id/index" => 'exhibitor_files#index'
  get "exhibitor_files/:exhibitor_id/new" => 'exhibitor_files#new'
  get "exhibitor_files/:exhibitor_id/edit/:id" => 'exhibitor_files#edit'
  get "exhibitor_files/:exhibitor_id/new/:original_document_id" => 'exhibitor_files#new'


  get "exhibitor_portals/media_files"       => 'media_files#index'
  get "media_files/exhibitors/:exhibitor_id/index"     => 'media_files#index'
  get "media_files/sessions/:session_id/index"     => 'media_files#index'
  get "mfiles_change_view" => 'media_files#change_view'

  get "sessions_media_files" => 'media_files#sessions_media_files'

  get "events/add_exhibitor_files_to_placeholders" => 'events#add_exhibitor_files_to_placeholders'
  post "events/create_exhibitor_files_for_placeholders" => 'events#create_exhibitor_files_for_placeholders'

  get "sessions/sessions_report" => 'reports#sessions_report' # used to live in sessions controller
  get "reports/sessions_report" => 'reports#sessions_report'
  post "reports/sessions_report" => 'reports#sessions_report'

  get "exhibitors/exhibitors_report" => 'reports#exhibitors_report'
  get "reports/exhibitors_report" => 'reports#exhibitors_report'
  post "reports/exhibitors_report" => 'reports#exhibitors_report'

  get "sessions/session_av_report"  => 'reports#sessions_av_report'
  get "reports/sessions_av_report"  => 'reports#sessions_av_report'
  post "reports/sessions_av_report" => 'reports#sessions_av_report'

  get "attendees/attendee_report" => 'reports#attendee_report'
  get "reports/attendee_report"   => 'reports#attendee_report'
  post "reports/attendee_report"  => 'reports#attendee_report'

  get "attendees/attendee_profile_report" => 'reports#attendee_profile_report'
  get "reports/attendee_profile_report"   => 'reports#attendee_profile_report'
  post "reports/attendee_profile_report"  => 'reports#attendee_profile_report'
  get 'reports/incomplete_daily_health_check_attendees_per_day' => 'reports#incomplete_daily_health_check_attendees_per_day'

  get "attendees/app_message" => 'attendees#app_message'
  get "attendees/app_message_company_data"        => 'attendees#app_message_company_data'
  get "attendees/app_message_business_units_data" => 'attendees#app_message_business_units_data'
  get "attendees/app_message_attendees_data"      => 'attendees#app_message_attendees_data'
  get "attendees/app_message_exhibitors_data"     => 'attendees#app_message_exhibitors_data'
  post "attendees/deliver_app_message"            => 'attendees#deliver_app_message'
  post "attendees/deliver_app_message_v2"            => 'attendees#deliver_app_message_v2'

  get "attendees/new_client_attendee"
  get "attendees/edit_client_attendee/:id"      => 'attendees#edit_client_attendee'
  post "attendees/create_client_attendee"
  put "attendees/update_client_attendee/:id"    => 'attendees#update_client_attendee'
  get "attendees/attendee_profile_landing/:event_id/:attendee_account_code/" => 'attendees#attendee_profile_landing'
  get "attendees/edit_attendee_profile/:id"     => 'attendees#edit_attendee_profile'
  put "attendees/update_attendee_profile/:id"   => 'attendees#update_attendee_profile'
  get "attendees/show_attendee_profile/:id"     => 'attendees#show_attendee_profile'


  get "attendees/validar_push" => 'attendees#validar_push'

  get "events/full_leaderboard_report" => 'reports#full_leaderboard_report'
  get "reports/full_leaderboard_report" => 'reports#full_leaderboard_report'
  post "reports/full_leaderboard_report" => 'reports#full_leaderboard_report'

  get "events/game_stats_report"   => 'reports#game_stats_report'
  get "reports/game_stats_report"  => 'reports#game_stats_report'
  post "reports/game_stats_report" => 'reports#game_stats_report'

  get "events/attendee_per_row_game_stats_report"   => "reports#attendee_per_row_game_stats_report"
  get "reports/attendee_per_row_game_stats_report"  => "reports#attendee_per_row_game_stats_report"
  post "reports/attendee_per_row_game_stats_report" => "reports#attendee_per_row_game_stats_report"

  get "events/download_notifications"

  get "events/download_qa"   => 'reports#download_qa'
  get 'reports/download_qa'  => 'reports#download_qa'
  post 'reports/download_qa' => 'reports#download_qa'

  get "events/download_home_buttons"
  get "events/download_attendees" => 'events#download_attendees'
  get "events/download_sessions" => 'events#download_sessions'
  get "events/download_sessions_full" => 'events#download_sessions_full'
  get "events/download_speakers" => 'events#download_speakers'
  get "events/download_exhibitors" => 'events#download_exhibitors'
  get "events/download_maps" => 'events#download_maps'
  get "events/download_mobileconfs" => 'events#download_mobileconfs'

  get '/feedbacks/create' => 'feedbacks#create'

	get '/feedbacks/results'         => 'reports#feedbacks_summary'
	get '/reports/feedbacks_summary' => 'reports#feedbacks_summary'

  get '/feedbacks/sessions_and_speakers_feedback' => 'reports#sessions_and_speakers_feedback'
  get '/reports/sessions_and_speakers_feedback'   => 'reports#sessions_and_speakers_feedback'
  post '/reports/sessions_and_speakers_feedback'  => 'reports#sessions_and_speakers_feedback'


  get '/booth_owners/multiple_new'         => 'booth_owners#multiple_new'
  post '/booth_owners/update_multiple_new' => 'booth_owners#update_multiple_new'
  get '/booth_owners/exhibitor_booth_owner/:exhibitor_id' => 'booth_owners#exhibitor_booth_owner'
  post '/booth_owners/add_booth_owner_for_exhibitor' => 'booth_owners#add_booth_owner_for_exhibitor'

  resources :attendees

  get '/sessions_attendee/:attendee_id/new' => 'sessions_attendees#new'

  get '/sessions_attendee/:attendee_id/multiple_new' => 'sessions_attendees#multiple_new'
  put  '/sessions_attendee/:attendee_id/update_multiple_new' => 'sessions_attendees#update_multiple_new'
  post  '/sessions_attendee/:attendee_id/update_multiple_new' => 'sessions_attendees#update_multiple_new'

  get '/sessions_trackowner/:trackowner_id/new' => 'sessions_trackowners#new'

  get '/sessions_trackowner/:trackowner_id/multiple_new' => 'sessions_trackowners#multiple_new'
  put  '/sessions_trackowner/:trackowner_id/update_multiple_new' => 'sessions_trackowners#update_multiple_new'
  post  '/sessions_trackowner/:trackowner_id/update_multiple_new' => 'sessions_trackowners#update_multiple_new'

  get '/events/deleteall_sessiondata_preivew' => 'events#deleteall_sessiondata_preivew'

  get '/events/deleteall_sessiondata'                    => 'events#deleteall_sessiondata'
  get '/events/deleteall_sessiontags'                    => 'events#deleteall_sessiontags'
  get '/events/deleteall_speakerdata'                    => 'events#deleteall_speakerdata'
  get '/events/deleteall_exhibitordata'                  => 'events#deleteall_exhibitordata'
  get '/events/deleteall_exhibitortags'                  => 'events#deleteall_exhibitortags'
  get '/events/deleteall_mapdata'                        => 'events#deleteall_mappingdata'
  get '/events/deleteall_eventconfigdata'                => 'events#deleteall_eventconfigdata'
  get '/events/deleteall_notificationdata'               => 'events#deleteall_notificationdata'
  get '/events/deleteall_home_buttondata'                => 'events#deleteall_home_buttondata'
  get '/events/deleteall_attendeedata'                   => 'events#deleteall_attendeedata'
  get '/events/deleteall_attendeetags'                   => 'events#deleteall_attendeetags'
  get '/events/populate_preselected_attendee_favourites' => 'events#populate_preselected_attendee_favourites'
  #new route for all integrations
  post '/events/refresh_external_api_import_script' => 'events#refresh_external_api_import_script'
  post '/events/external_api_import_script' => 'events#external_api_import_script'
  get '/events/refresh_custom_adjustment_script' => 'events#refresh_custom_adjustment_script'

	get "/events/change_event/:event_id" => 'events#change_event'

  # get "event_settings/edit_event_settings/:id" => 'speakers#edit_event_settings'
  # get '/event_settings/edit_event_settings' => 'event_settings#edit_event_settings'
  get "event_settings/edit_event_settings"
  # get event_settings/index
  put "event_settings/update_event_settings"
  post "event_settings/update_event_settings"

  get 'event_settings/edit_general_portal_settings'
  put 'event_settings/update_general_portal_settings'
  post 'event_settings/update_general_portal_settings'
  get 'event_settings/edit_restricted_event_settings'
  put 'event_settings/update_restricted_event_settings'
  post 'event_settings/update_restricted_event_settings'

  get "event_settings/edit_event_tabs" => 'event_settings#edit_event_tabs'
  get "event_settings/edit_exhibitor_event_tabs" => 'event_settings#edit_exhibitor_event_tabs'
  put "event_settings/update_tab"
  post "event_settings/update_tab"

  put "settings/update_tab"               => "event_settings#update_tab"
  post "settings/update_tab"              => "event_settings#update_tab"
  put "settings/update_event_settings"    => "event_settings#update_event_settings"
  post "settings/update_event_settings"   => "event_settings#update_event_settings"


  get "event_settings/edit_session_notes_content" => 'event_settings#edit_session_notes_content'
  put "event_settings/update_session_notes_content"
  post "event_settings/update_session_notes_content"

  get "event_settings/edit_av_requirements" => 'event_settings#edit_av_requirements'
  put "event_settings/update_av_requirements"
  post "event_settings/update_av_requirements"

  get "event_settings/edit_headers_and_footers" => 'event_settings#edit_headers_and_footers'
  put "event_settings/update_headers_and_footers"
  post "event_settings/update_headers_and_footers"

  get "event_settings/edit_exhibitor_welcome" => 'event_settings#edit_exhibitor_welcome'
  put "event_settings/update_exhibitor_welcome"
  post "event_settings/update_exhibitor_welcome"

  get "event_settings/show_messages" => 'event_settings#show_messages'
  # get "event_settings/new_message" => 'event_settings#new_message'
  # get "event_settings/edit_message" => 'event_settings#edit_message'
  # put "event_settings/update_message" => 'event_settings#update_message'
  # post "event_settings/update_message" => 'event_settings#update_message'


  get "event_settings/edit_mobile_settings"
  put "event_settings/update_mobile_settings"
  patch "event_settings/update_mobile_settings"

  get "event_settings/edit_requirements"
  put "event_settings/update_requirements"
  post "event_settings/update_requirements"

  get "event_settings/edit_banners"
  put "event_settings/update_banners"
  post "event_settings/update_banners"

  #mobile_web_settings

  # get "mobile_web_settings/edit_settings"
  # # get event_settings/index
  # put "mobile_web_settings/update_settings"
  # post "mobile_web_settings/update_settings"

  get "messages/display_message/:id" => 'messages#display_message'
  get "messages/subscribe/:token" => 'messages#subscribe'
  get "messages/unsubscribe/:token" => 'messages#unsubscribe'


  get '/location_mappings/rooms' => 'location_mappings#rooms_index'
  get '/location_mappings/booths' => 'location_mappings#booths_index'

  get '/location_mappings/select_map' => 'location_mappings#select_map'

  get '/location_mappings/set_coordinates/:map_id' => 'location_mappings#set_coordinates'

  put "location_mappings/update_coordinate/:event_id" => 'location_mappings#update_coordinate'
  post "location_mappings/update_coordinate/:event_id" => 'location_mappings#update_coordinate'
  post 'location_mappings/update_size' => 'location_mappings#update_size'
  post '/location_mappings/location_mapping_product' => 'location_mappings#location_mapping_products'
  get  '/location_mappings/product/:location_mapping_id' => 'location_mappings#mapping_product'

  get '/notifications/send_data_update' => 'notifications#send_data_update'
  get '/notifications/send_ce_credits_on' => 'notifications#send_ce_credits_on'
  get '/notifications/send_ce_credits_off' => 'notifications#send_ce_credits_off'

  get '/ce_credits/get_certificate' => 'ce_credits#get_certificate'
  resources :event_file_types

  get "event_files/show_banner/:id"               => "event_files#show_banner"
  get "event_files/edit_banner/:id"               => "event_files#edit_banner"
  get "event_files/new_banner"                    => "event_files#new_banner"
  post "event_files/create_banner"                => "event_files#create_banner"
  put "event_files/update_banner/:id"             => "event_files#update_banner"
  post "event_files/delete_banner/:id"            => "event_files#delete_banner"
  resources :event_files

  resources :event_maps

  get '/event_maps/:map_id/add_rooms' => 'event_maps#add_rooms'
  put  '/event_maps/:map_id/update_add_rooms' => 'event_maps#update_add_rooms'
  patch  '/event_maps/:map_id/update_add_rooms' => 'event_maps#update_add_rooms'
  post  '/event_maps/:map_id/update_add_rooms' => 'event_maps#update_add_rooms'

  resources :tabs

  post '/users' => 'users#create' #override devise
  get '/users/new_install' => 'users#new_install'
  get '/users/create_new_install' => 'users#create_new_install'
  get '/users/new_speaker_portal_user/:speaker_id' => 'users#new_speaker_portal_user'
  get '/users/create_speaker_portal_user' => 'users#create_speaker_portal_user'
  get '/users/deactivate/:id' => 'users#deactivate'
  get '/users/reactivate/:id' => 'users#reactivate'

  get "speakers/edit_travel_detail/:id" => 'speakers#edit_travel_detail'
  get "speakers/edit_payment_detail/:id" => 'speakers#edit_payment_detail'

  get "speakers/speaker_report" => 'reports#speaker_report'
  get "reports/speaker_report"  => 'reports#speaker_report'
  post "reports/speaker_report" => 'reports#speaker_report'

  put "speakers/update_travel_detail"
  post "speakers/update_travel_detail"
  put "speakers/update_payment_detail"
  post "speakers/update_payment_detail"
  # get "speakers/download_zip/:id" => "speakers#download_zip"
  get "speakers/download_all_zip" => "speakers#download_all_zip"

  get '/speakers/bulk_add_speaker_photos'
  post '/speakers/bulk_create_speaker_photos'

  get '/script_types/new_button_from_script_type/:id'  => 'script_types#new_button_from_script_type'

  get '/video_views' => 'video_views#index'
  get '/video_views/ce_checkins/:session_code' => 'video_views#ce_checkedin_attendees'
  get '/video_views/page_views_attendees/:session_code' => 'video_views#page_viewed_attendees'
  get '/video_views/video_views_attendees/:session_code' => 'video_views#video_viewed_attendees'
  get '/video_views/show_pages_views/:id' => 'video_views#show_pages_views'
  get '/video_views/show_video_views/:id' => 'video_views#show_video_views'
  get '/video_views/history/:id' => 'video_views#history'
  # video views reports
  get '/video_views/report' => 'video_views#index_report'
  get '/video_views/ce_checkins/:session_code/report' => 'video_views#ce_checkedin_attendees_report'
  get '/video_views/page_views_attendees/:session_code/report' => 'video_views#page_viewed_attendees_report'
  get '/video_views/video_views_attendees/:session_code/report' => 'video_views#video_viewed_attendees_report'

  resources :ce_certificates

  get '/exhibitor_portals/chat' => 'chats#index'
  post '/chats/update'
  put '/chats/enable'
  put '/chats/enable_livestream/:session_id' => 'chats#enable_livestream'
  put '/chats/enable_moderator_notification_sound/:session_id' => 'chats#enable_moderator_notification_sound'

  post '/chats/download'
  get '/moderator_portals/chat/:session_id' => 'chats#livestream'

  # get '/forgot_password' => 'passwords#create'
  # confirm_user_with_two_factor
  devise_scope :user do
    get   '/users/generate_password_and_enable_two_fa' => 'invitations#show_with_two_factor', as: :generate_passord_with_two_fa
    post  '/users/confirm_with_two_factor'        => 'invitations#confirm_with_two_factor', as: :confirm_with_two_factor
    post  '/users/confirm_without_two_factor'     => 'invitations#confirm_without_two_factor', as: :confirm_without_two_factor
    get   'users/backup_codes'                         => 'invitations#edit'
    get   '/forgot-password'     => 'passwords#new' ,      as: :new_user_password
    get   '/users/password/edit' => 'passwords#edit',      as: :edit_user_password
    patch '/users/password'      => 'passwords#update',    as: :user_password
    put   '/users/password'      => 'passwords#update'
    post  '/users/password'      => 'passwords#create'
    patch 'user_event/:user_event_id/users/:user_id/update_user_role_event' => "user_event_roles#update"
  end

  devise_for :users, :controllers => { :sessions => "managers", :passwords => "passwords",:confirmations => "invitations" }, :skip => [:passwords]
  resource :two_factor_settings, except: [:index, :show]
  resource :reset_two_factor, except: [:index, :show, :update] do
    post 'lost_device'
  end
#  devise_for :admins, :controllers => { :sessions => "admins/sessions" }

  resources :users do
    member do
      scope controller: 'profiles' do
        get    :profile
        post   :update_general
        patch  :update_password
        post   :create_two_factor
        post   :regenerate_backup_codes
        delete :two_factor
        get    :account
        put    :update_account
      end
      post  :impersonate
      get   :show_user_event_role
      post  :add_user_event
    end
    collection do
      get  :user_event_role
      post :create_user_role
    end
    post :stop_impersonating, on: :collection
  end

  resources :app_images

  resources :device_app_image_sizes

  resources :trackowners

  resources :moderators

  #resources :admins

  #devise_for :admins

  resources :sponsor_specifications

  resources :location_mapping_types

  resources :location_mappings

  resources :sessions_speakers

  resources :sessions_attendees

  resources :sessions_trackowners

  resources :sessions_subtracks

  resources :users_events

  resources :users_organizations

  resources :booths

  resources :exhibitor_links

  resources :exhibitor_files

  resources :exhibitor_products

  resources :coupons

  resources :enhanced_listings

  resources :sponsor_level_types

  resources :sponsor_types

  resources :link_types

  resources :links

  resources :speaker_types

  # deprecated
  # resources :sessions_speakers

  resources :record_comments

  resources :record_types

  resources :records

  resources :map_types

  resources :maps

  resources :messages

  resources :rooms

  resources :notifications

  resources :home_buttons

  resources :custom_lists

  resources :custom_list_items

  resources :home_button_entries #old version of home buttons and custom_lists with janky code

  resources :home_button_groups #old version of home buttons and custom_lists with janky code

  resources :exhibitors do
    member do
      get 'purchase_history'
    end
  end

  resources :exhibitor_staffs

  resources :speakers

  resources :speaker_files

  resources :sessions, :as => :event_sessions

  resources :session_files

  resources :session_file_versions

  resources :session_av_requirements

  resources :room_layouts

  resources :subtracks

  resources :tracks

  resources :mobile_web_settings

  resources :scripts

  resources :script_types

  resources :custom_emails

  resources :exhibitor_portal_global_configs

  # resources :speaker_payment_details

  resources :events do
  	collection do
  		get 'indexfororg'
  	end

  	#member do
  	#	get 'config'
  	#end
  end

  resources :organization_events

  resources :organizations do
  	collection do
  		get 'indexforuser'
  	end
  end
  get "home/index"
  get '/home' => 'home#index'
  get '/home/select_event' => 'home#select_event'
  get '/home/set_event' => 'home#set_event'

  # Registration Portal hotel_information

  get '/:event_id/registrations'                    => "registrations#index"
  get '/:event_id/registrations/new'                => "registrations#new"
  get '/:event_id/registrations/member'             => "registrations#member"
  post '/:event_id/registrations/create'            => "registrations#create"
  # post '/:event_id/registrations/sign_in'         => "registrations#sign_in"
  get '/:event_id/registrations/:id/products'       => "registrations#products"
  put  '/:event_id/registrations/update_cart/:id'   => "registrations#update_cart"
  delete  '/:event_id/registrations/delete_item/:cart_id'   => "registrations#delete_item"
  get '/:event_id/registrations/attendee/cart/:id'       => "registrations#cart"
  get '/:event_id/registrations/attendee/:attendee_id/select_tag' => "registrations#select_tag"
  post '/:event_id/registrations/attendee/update_attendee_form'  => "registrations#update_attendee_form"
  get '/:event_id/registrations/attendee/create_order_cart/:id'       => "registrations#create_order_cart"

  get '/:event_id/registrations/attendee/payment/:id/:order_id'       => "registrations#attendee_payment"
  get '/:event_id/registrations/:user_id/:form_id/payment_success'  => "registrations#payment_success"
  get '/:event_id/registrations/:user_id/:form_id/payment_failed'  => "registrations#payment_failed"

  get '/:event_id/registrations/verify/:slug'       => "registrations#verify"
  get '/:event_id/registrations/edit_profile/:slug' => "registrations#edit_profile"
  put '/:event_id/registrations/update_profile'     => "registrations#update_profile"
  get '/:event_id/registrations/login_to_profile'   => "registrations#already_registered"
  get '/:event_id/registrations/confirm/:token'     => "confirmations#create"
  get '/:event_id/confirmations/resend/:id'         => "confirmations#resend"
  get '/:event_id/registrations/agenda'             => "registrations#agenda"
  get '/:event_id/registrations/speakers'           => "registrations#speakers"
  get '/:event_id/registrations/exhibitors'         => "registrations#exhibitors"
  get '/:event_id/registrations/sponsors'           => "registrations#sponsors"
  get '/:event_id/registrations/hotel_information'  => "registrations#hotel_information"
  get '/:event_id/registrations/profile/:slug'      => "registrations#profile"
  delete '/registrations/remove_bg_img'             => "registrations#remove_bg_img"
  post '/registrations/create_section'              => "registrations#create_section"
  post '/registrations/create_column/:section_id'   => "registrations#create_column"
  delete '/registrations/remove_section'            => "registrations#remove_section"
  delete '/registrations/remove_column/:section_id' => "registrations#remove_column"
  get '/:event_id/registrations/registered/:id'     => "registrations#registered"
  get '/:event_id/registrations/confirm/user/:id'    => "registrations#confirmed"
  get '/:event_id/registrations/:user_id/instruction' => "registrations#instruction"
  get '/:event_id/ym_registrations'                 => "registrations#register_with_ym"
  post '/registrations/:order_id/apply_coupon'      => "registrations#apply_coupon"
  post '/registrations/:order_id/remove_coupon'     => "registrations#remove_coupon"

  # Simple registration
  get '/:event_id/event_registrations/new'          => "event_registrations#new"
  post '/:event_id/event_registrations/create'      => "event_registrations#create"
  get  '/:event_id/event_registrations/show/:slug'  => "event_registrations#show"
  get  '/auth/:provider/callback'                   => "event_registrations#google_calendar_callback"
  get  '/auth/:provider'                            => "event_registrations#google_calendar_callback"
  get '/:event_id/event_registrations'              => "event_registrations#new"
  get '/:event_id/event_registrations/icalendar'    => "event_registrations#icalendar"
  get '/event_registrations/confirm'                => "event_registrations#confirm"

  get   '/:event_id/speaker_registrations/new'                => "speaker_registrations#new"
  post  '/:event_id/speaker_registrations/create'             => "speaker_registrations#create"
  get   '/speaker_registrations/confirm'                      => "speaker_registrations#confirm"
  post  '/speaker_registrations/create_speaker_portal_user'   => "speaker_registrations#create_speaker_portal_user"
  get   '/:event_id/speaker_registrations/success'            => "speaker_registrations#success"

  # Exhibitor registration
  get '/:event_id/exhibitor_registrations'                    => "exhibitor_registrations#index"
  get '/:event_id/exhibitor_registrations/new'                => "exhibitor_registrations#new"
  post '/:event_id/exhibitor_registrations/create'            => "exhibitor_registrations#create"
  get '/:event_id/exhibitor_registrations/:user_id/payment_success'  => "exhibitor_registrations#payment_success"
  get '/:event_id/exhibitor_registrations/registered/:id'     => "exhibitor_registrations#registered"
  get '/:event_id/exhibitor_registrations/agenda'             => "exhibitor_registrations#agenda"
  get '/:event_id/exhibitor_registrations/speakers'           => "exhibitor_registrations#speakers"
  get '/:event_id/exhibitor_registrations/confirm/user/:id'   => "exhibitor_registrations#confirmed"
  get '/:event_id/exhibitor_registrations/cart_order/:id'     => "exhibitor_registrations#create_order_cart"


  get 'exhibitor_portals/staff_members'        => 'exhibitor_staffs#index'
  get 'exhibitor_staffs/create_vchat_room/:id' => 'exhibitor_staffs#create_vchat_room'
  get 'exhibitor_staffs/delete_vchat_room/:id' => 'exhibitor_staffs#delete_vchat_room'
  get 'exhibitor_staffs/enable_lead_retrieval/:id' => 'exhibitor_staffs#enable_lead_retrieval'
  get 'exhibitor_staffs/delete_lead_retrieval/:id' => 'exhibitor_staffs#delete_lead_retrieval'
  get 'exhibitor_staffs/my_orders'             => 'exhibitor_staffs#exhibitor_staffs/my_orders'
  get 'exhibitor_staffs/staffs/:id'            => 'exhibitor_staffs#staffs'
  get 'exhibitor_staffs/new_staff/:id'         => 'exhibitor_staffs#new_staff'
  post 'exhibitor_staffs/new_staff/:exhibitor_id'   => 'exhibitor_staffs#create_staff'

  # Custom Emails
  # get 'custom_emails'                   => 'custom_emails#new'
  # post 'custom_emails/create'            => "custom_emails#create"

  get '/events/configure/:event_id' => 'events#configure'
  post '/events/upload_sessions' => 'events#upload_sessions'
  post '/events/upload_sessions_full' => 'events#upload_sessions_full'
  post '/events/upload_speakers' => 'events#upload_speakers'
  post '/events/upload_exhibitors' => 'events#upload_exhibitors'
  post '/events/upload_captrust_exhibitors' => 'events#upload_captrust_exhibitors'
  post '/events/upload_maps' => 'events#upload_maps'
  post '/events/upload_mobileconfs' => 'events#upload_mobileconfs'
  post '/events/upload_attendees' => 'events#upload_attendees'
  post '/events/upload_notifications' => 'events#upload_notifications'
  post '/events/upload_home_buttons' => 'events#upload_home_buttons'

  post '/update_positions' => "home_buttons#update_positions"
  get '/home_buttons_mobile_preview' => "home_buttons#mobile_preview"
  get '/mobile_home_page_content' => 'home_buttons#mobile_home_page_content'

  #get '/events/indexfororg/:org_id' => 'events#indexfororg'

  get '/sessions/indexforevent/:org_id/:event_id' => 'sessions#indexforevent'

  get '/links/new/:session_id' => 'links#new'

  get '/coupons/new/:exhibitor_id' => 'coupons#new'
  get '/enhanced_listings/new/:exhibitor_id' => 'enhanced_listings#new'
  get '/exhibitor_links/new/:exhibitor_id' => 'exhibitor_links#new'
  get '/sponsor_specifications/edit/:exhibitor_id' => 'sponsor_specifications#edit'

  get '/home_button_entries/new/:home_button_group_id' => 'home_button_entries#new'

  get '/events/new/:organization_id' => 'events#new'


  #client viewing of home button entry categories, extras, videos, social
  get '/home_button_groups/category/:entry_category' => 'home_button_groups#show_category_entries'

  #mobile data actions
  get '/home_button_groups/mobile_data/:event_id/:record_start_id' => 'home_button_groups#mobile_data'
  get '/home_button_groups/mobile_data/extras/:event_id/:record_start_id' => 'home_button_groups#mobile_data_extras'
  get '/home_button_groups/mobile_data/videos/:event_id/:record_start_id' => 'home_button_groups#mobile_data_videos'
  get '/home_button_groups/mobile_data/socials/:event_id/:record_start_id' => 'home_button_groups#mobile_data_socials'

  #get '/exhibitors/mobile_data/:event_id/:record_start_id' => 'exhibitors#mobile_data_limit'
  get '/exhibitors/mobile_data/:event_id/:record_start_id' => 'exhibitors#mobile_data'
  get '/exhibitors/mobile_data_no_limit/:event_id' => 'exhibitors#mobile_data_no_limit'
  get '/exhibitors/tags/leaf/mobile_data/:event_id/:record_start_id' => 'exhibitors#mobile_data_exhibitor_leaf_tags'
  get '/exhibitors/tags/nonleaf/mobile_data/:event_id/:record_start_id' => 'exhibitors#mobile_data_exhibitor_nonleaf_tags'
  #get '/exhibitors/mobile_data_count/:event_id/:record_start_id' => 'exhibitors#mobile_data_count'

  get '/sessions/mobile_data/:event_id/:record_start_id' => 'sessions#mobile_data'
	get '/sessions/mobile_data_sessions_only/:event_id/:record_start_id' => 'sessions#mobile_data_sessions_only'
  get '/sessions/tags/leaf/mobile_data/:event_id/:record_start_id' => 'sessions#mobile_data_session_leaf_tags'
  get '/sessions/tags/nonleaf/mobile_data/:event_id/:record_start_id' => 'sessions#mobile_data_session_nonleaf_tags'
	get '/sessions/sponsors/mobile_data/:event_id/:record_start_id' => 'sessions#mobile_data_session_sponsors'

  post '/edit_mobile_web_settings/:setting_id' => 'event_settings#edit_mobile_web_settings'
  post '/save_editor_css' => 'event_settings#save_css'


  #get '/sessions/mobile_data_count/:event_id/:record_start_id' => 'sessions#mobile_data_count'

  get '/speakers/mobile_data/:event_id/:record_start_id' => 'speakers#mobile_data'
  get '/tracks/mobile_data/:event_id/:record_start_id' => 'tracks#mobile_data'
  get '/event_maps/mobile_data/:event_id/:record_start_id' => 'event_maps#mobile_data'
  get '/notifications/mobile_data/:event_id' => 'notifications#mobile_data'

  get '/events/mobile_data/:event_id/:record_start_id' => 'events#mobile_data'

  get '/attendees/mobile_data/:event_id/:record_start_id' => 'attendees#mobile_data'
  get '/attendees/mobile_data_attendee_sessions/:event_id' => 'attendees#attendee_sessions'
  get '/attendees/mobile_data_attendee_exhibitors/:event_id' => 'attendees#attendee_exhibitors'
  get '/attendees/iattend/list' => 'attendees#iattend_list'
  get '/attendees/iattend/update' => 'attendees#iattend_update'
  get '/attendees/favouritessync/list' => 'attendees#favouritessync_list'
  get '/attendees/favouritessync/update' => 'attendees#favouritessync_update'
  get '/attendees/exhibitor_favouritessync/list' => 'attendees#exhibitor_favouritessync_list'
  get '/attendees/exhibitor_favouritessync/update' => 'attendees#exhibitor_favouritessync_update'

  post '/update_event_sponsor_level_types' => 'sponsor_level_types#update_event_sponsor_level_types'
  post '/remove_from_event_sponsor_level_type' => 'sponsor_level_types#remove_from_event_sponsor_level_type'
  post '/sponsor_level_types/add_medal_image' => 'sponsor_level_types#add_medal_image'

  get '/chat_requests/attendee_info', :controller => 'chat_requests', :action => 'options', :constraints => {:method => 'OPTIONS'}
  get '/chat_requests/attendee_info' => 'chat_requests#attendee_info'
  get '/chat_requests/index' => 'chat_requests#index'


  get '/survey_images/download' => 'survey_images#download'
  delete '/survey_images/reset' => 'survey_images#reset'
  get '/survey_images/attendee_list/:survey_id' => 'survey_images#attenee_list_not_completed_survey'
  get '/survey_images/unattended_attendee_report' => 'survey_images#unattended_attendee_report'
  get '/survey_images/attended_attendee_report' => 'survey_images#attended_attendee_report'
  get '/survey_images/delete_survey_images' => 'survey_images#delete_survey_images'

  resources :survey_images

  resources :event_tickets

  get '/attendees/:attendee_code/cms_generate_lead_surveys_report/:event_id' => 'attendees#cms_generate_lead_surveys_report'

  resources :product_categories do
    collection do
      get 'create_default_product_categories'
    end
    member do
      post 'add'
    end
  end


  get '/reorder_product_category'       => "product_categories#reorder_product_category"
  post '/update_order_product_category' => "product_categories#update_order_product_category"
  get '/reorder_product'       => "products#reorder_product"
  post '/update_order_product' => "products#update_order_product"
  #Transaction
  get '/:event_id/registrations/payment/:id'        => "transactions#new"
  get '/:event_id/registrations/payment/:id/:product_id' => "transactions#get_merchant_form"
  post '/:event_id/registrations/payment/create'    => "transactions#create"
  post '/:event_id/registrations/payment/create_checkout_session_stripe' => 'transactions#stripe_create_payment', as: :stripe_checkout_session
  post '/orders/paypal/create_payment'  => 'transactions#paypal_create_payment', as: :paypal_create_payment
  post '/orders/paypal/execute_payment' => 'transactions#paypal_execute_payment', as: :paypal_execute_payment
  post '/orders/stripe/create_payment'  => 'transactions#stripe_create_payment', as: :stripe_create_payment
  post '/exhibitors/orders/product_payment' => "transactions#payment", as: :exhibitor_payment
  post '/exhibitors/orders/zero_payment'  => "transactions#exhibitor_zero_total_payment"
  post '/orders/stripe/create_payment_attendee'  => 'registrations#stripe_create_payment', as: :stripe_create_payment_attendee
  get  '/orders/stripe/complete_payment' => 'transactions#stripe_complete_payment'
  post '/orders/affinipay/create_payment' => 'registrations#affinipay_create_payment'
  post '/orders/zero_payment'  => 'registrations#zero_payment'
  get '/:event_id/exhibitors/:transaction_id/payment_success' => "transactions#exhibitor_affinipay_payment_success"

  get '/:event_id/exhibitor_registrations/payment/:id/select_booth' => "transactions#exhibitor_select_booth"
  post '/transaction/exhibitor/add_to_cart' => 'exhibitor_registrations#add_to_cart'
  post '/transaction/exhibitor/remove_from_cart' => 'transactions#exhibitor_remove_from_cart'
  get '/:event_id/transactions/payment/:cart_id' => 'transactions#exhibitor_payment'
  post '/orders/paypal/create_payment_for_exhibitor'  => 'transactions#create_payment_for_exhibitor'
  post '/orders/paypal/execute_payment_for_exhibitor'  => 'transactions#execute_payment_for_exhibitor'
  post '/:event_id/exhibitor_registrations/exhibitor_payment_success' => 'transactions#exhibitor_payment_success'
  get '/orders/stripe/complete_payment_exhibitor' => 'transactions#stripe_complete_payment_exhibitor'
  get '/orders/stripe/complete_payment_registration_form' => 'registrations#stripe_complete_payment_registration_form'
  get '/:event_id/orders/stripe/complete_payment_order/:mode_of_payment_id' => 'registrations#stripe_create_payment_order'
  get '/exhibitor_portals/complete_purchase' => 'exhibitor_portals#complete_purchase'
  get '/:event_id/exhibitor_registrations/cart/:id'  =>  'exhibitor_registrations#cart'
  get '/:event_id/exhibitor_registrations/payment/:cart_id/:order_id' => "transactions#exhibitor_payment"
  get '/:event_id/exhibitor_portals/payment/:cart_id/:order_id' => "exhibitor_portals#exhibitor_payment"
  get '/:event_id/exhibitor_portals/cart_order/:id'     => "exhibitor_portals#create_order_cart"

  resources :mode_of_payments


  root :to => "home#index"

   # events listing features
   get '/sort_search_toggle_view', to: 'events#sort_search_toggle_view'

  #Program Feed
  get '/:event_id/program', to: 'program_feeds#index'
  get '/:event_id/program_speaker', to: 'program_feeds#by_speakers'
  get '/:event_id/program/speaker/:speaker_id', to: 'program_feeds#speaker_sessions_details'
  get '/:event_id/program_exhibitor', to: 'program_feeds#by_exhibitors'
  get '/:event_id/program/exhibitor/:exhibitor_id', to: 'program_feeds#exhibitor_sessions_details'
  get '/:event_id/program_sponsored_exhibitor', to: 'program_feeds#by_sponsor_exhibitors'
  get '/:event_id/program_keynote_speaker', to: 'program_feeds#by_keynote_speakers'
  get '/:event_id/program/login_page', to: 'program_feeds#login_page'
  post '/:event_id/program/login', to: 'program_feeds#login'
  delete '/:event_id/program/logout', to: 'program_feeds#logout', as: :program_feed_logout
  post '/:event_id/favourite', to: 'program_feeds#favourite'

  #send attendee calender invite
  post '/email/calender_invite/:id', to: 'attendees#send_calender_invite'

  #Purchase
  resources :purchases do
    member do
      post 'refund'
      post 'transaction_refund'
    end
    collection do
      get 'refund_purchases'
      get 'exhibitor_purchases'
      get 'attendee_purchases'
      get 'transactions'
      get 'show_transactions/:order_id', action: 'show_transactions'
      post 'charge_id_refund/:charge_id', action: 'charge_id_refund'
      post 'create_user/:order_id'      , action: 'user'
      get  'item_purchases'
      get  'purchase_amount'
    end
  end

  #Member
  resources :members do
    collection do
      get  'unsubscribe'
      post 'submit_unsubscribe'
      get  '/:organization_id/subscribe', to: 'members#for_organization_subscribe'
      get  '/:organization_id/unsubscribe', to: 'members#for_organization_unsubscibe'
      post 'upload_members'
      get  '/attendee_register/:event_id', to: 'members#attendee_register'
      post 'attendee_register_submit'
    end
  end
  get '/member/:event_id', to: 'members#show_event'

  resources :members_listing do
    collection do
      get 'organization_email_queue'
      get 'show_email/:id', to: 'members_listing#show_email'
      delete 'destroy_email/:id', to: 'members_listing#destroy_email'
      post 'create_member_by_client'
      get  'send_reset_password_mail'
    end
  end

  resources :organization_email_templates do
    collection do
      delete 'destroy_organization_email_file'
    end
  end

  get '/organization_settings/upload_subscribe_unsubscribe_settings', to: 'organization_settings#new_subscribe_unsubscribe_settings'
  post '/organization_settings/subscribe_unsubscribe_settings', to: 'organization_settings#create_subscribe_unsubscribe_settings'

  #Purchase
  # resources :purchases do
  #   member do
  #     post 'refund'
  #   end
  #   collection do
  #     get 'refund_purchases'
  #   end
  # end

  #Attendee Badge
  resources :badge_templates do
    collection do
      post 'fetch_preview_from_labelary'
    end
  end

  # Custom Form
  resources :custom_forms

  #Session Subtitle
  get '/sessions/:id/subtitles' => 'session_subtitles#index'
  get '/sessions/:id/subtitle/new' => 'session_subtitles#new'
  post '/sessions/subtitles/create' => 'session_subtitles#create'
  get '/sessions/:id/subtitles/edit' => 'session_subtitles#edit'
  put '/sessions/subtitles/update' => 'session_subtitles#update'
  delete '/sessions/:id/subtitles/destroy' => 'session_subtitles#destroy'

  # For webhook Events
  # post '/webhooks/affinipay', to: 'webhooks#affinipay'
  # get  '/webhooks', to: 'webhooks#index'
  resources :webhooks, only: [:index, :show] do
    collection do
      post 'affinipay'
      post 'refund/:charge_id', action: 'refund'
    end
  end

  get '/:event_id/attendee_badge_print' => 'attendee_badge_prints#home'
  get '/:event_id/attendee_badge_print/exhibitors' => 'attendee_badge_prints#home_exhibitor'
  get '/:event_id/attendee_badge_print/speakers' => 'attendee_badge_prints#home_speaker'
  get '/:event_id/attendee_badge_print/search_attendee' => 'attendee_badge_prints#search_attendee'
  get '/:event_id/attendee_badge_print/print_badge/:attendee_id' => 'attendee_badge_prints#print_badge'
  post '/:event_id/attendee_badge_print/print_badge_pin_based' => 'attendee_badge_prints#print_badge_pin_based'
  post '/:event_id/attendee_badge_print/print_badge_over_ride' => 'attendee_badge_prints#print_badge_over_ride'

  resources :download_requests do
    collection do
      get 'request_file'
    end
  end

  # Handle routing error when no routes match
  get '*path' => redirect('/')

end
