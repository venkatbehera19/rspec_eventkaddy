class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user

    #public access abilities
    can :leaderboard_for_projector, AppGame
    can :leaderboard_for_projector_for_full_completion, AppGame
    can :mobile_data, HomeButtonGroup
    can :mobile_data_extras, HomeButtonGroup
    can :mobile_data_videos, HomeButtonGroup
    can :mobile_data_socials, HomeButtonGroup
    can :mobile_data, HomeButtonEntry
    can :mobile_data, HomeButton
    can :mobile_data, CustomList
    can :mobile_data, Exhibitor
    can :mobile_data_no_limit, Exhibitor
    can :mobile_data_exhibitor_leaf_tags, Exhibitor
    can :mobile_data_exhibitor_nonleaf_tags, Exhibitor
    can :mobile_data_limit, Exhibitor
    can :mobile_data_count, Exhibitor
    can :mobile_data, Speaker
    can :mobile_data, LocationMapping
    can :mobile_data, Notification
    can :mobile_data, EventMap
    can :mobile_data, Track
    can :mobile_data, Subtrack
    can :mobile_data, Session
    can :mobile_data_sessions_only, Session
    can :mobile_data_session_leaf_tags, Session
    can :mobile_data_session_nonleaf_tags, Session
    can :mobile_data_session_sponsors, Session
    can :mobile_data_count, Session
    can :mobile_data, Event
    can :mobile_data, Attendee
    can :attendee_sessions, Attendee
    can :attendee_exhibitors, Attendee
    can :iattend_list, Attendee
    can :iattend_update, Attendee
    can :favouritessync_list, Attendee
    can :favouritessync_update, Attendee
    can :exhibitor_favouritessync_list, Attendee
    can :exhibitor_favouritessync_update, Attendee
    can :generate_spreadsheet, Feedback
    can :create, Feedback
    can :gallery_photos_json_data, Event
    can :generate_ce_sessions_pdf_report, Attendee
    can :generate_lead_surveys_report, Attendee
    can :attendee_profile_landing, Attendee
    can :edit_attendee_profile, Attendee
    can :update_attendee_profile, Attendee
    can :show_attendee_profile, Attendee
    can :email_attendee_notes, Attendee
    can :new, User
    can :create, User
    can :unsubscribe, User
    can :submit_unsubscribe, User
    can :for_organization_subscribe, User
    can :for_organization_unsubscibe, User
    can :upload_members, User

    if user.role? :super_admin
      can :manage, :all
      can :see_timestamps, User
      can :update_coordinate, LocationMapping
      can :dev, :all
      can :client, :all
      can :custom_adjustments, :all

    elsif user.role? :client
      # manage means ANY action in the controller, not just crud;
      # a lot of these might accidentally become too generous as new endpoints are
      # added intended for dev, but should usually be okay since the most important
      # actions on Event are not available to clients
      can :manage,[AppMessageThread,Tag,Track,Subtrack,Session,Speaker,SpeakerFile,Exhibitor,HomeButtonGroup,HomeButtonEntry,LocationMapping,
                   LocationMappingType,EventMap,Coupon,EnhancedListing,ExhibitorLink,SponsorSpecification,Attendee,SessionFile,SessionFileVersion,RoomLayout,EventSetting,SessionsAttendee,Message,SessionsTrackowner,Trackowner,Link,HomeButton,CustomList,CustomListItem,ExhibitorFile,Setting,Survey,ScavengerHunt,ScavengerHuntItem,AppGame,AppBadge,AppBadgeTask,AttendeesAppBadgeTask,AttendeesAppBadge,EventsAvListItem, ProductCategory]

      can :client, :all
      can :download_sessions_async, Event
      can :download_sessions_full_async, Event
      can :index, Notification
      can :show, Notification
      can :new, Notification
      can :edit, Notification
      can :create, Notification
      can :update, Notification
      can :destroy, Notification
      can :send_data_update, Notification
      can :send_ce_credits_on, Notification
      can :send_ce_credits_off, Notification
      can :configure, Event
      can :edit_tags, Tag
      can :update_tags, Tag
      can :edit_preset_tag_options, Event
      can :update_preset_tag_options, Event
      can :edit_type_to_pn_hash, Event
      can :update_type_to_pn_hash, Event
      can :game_statistics, Event
      can :game_stats_report, Event
      can :attendee_per_row_game_stats_report, Event
      can :full_leaderboard_report, Event
      can :delete_abandoned_tags, Event
      can :download_generated_certificates_as_zip, Event
      can :upload_sessions, Event
      can :upload_exhibitors, Event
      can :upload_speakers, Event
      can :upload_maps, Event
      can :upload_mobileconfs, Event
      can :upload_attendees, Event
      can :upload_notifications, Event
      can :upload_home_buttons, Event
      can :upload_sessions_full, Event
      can :download_sessions, Event
      can :download_sessions_full, Event
      can :download_speakers, Event
      can :download_exhibitors, Event
      can :download_maps, Event
      can :download_attendees, Event
      can :download_logins, Event
      can :download_notifications, Event
      can :download_qa, Event
      can :download_home_buttons, Event
      can :add_files_to_placeholders, Event
      can :adp_refresh_sessions, Event
      can :refresh_external_api_import_script, Event
      can :refresh_exhibitors_from_xml, Exhibitor
      can :deleteall_sessiondata, Event
      can :deleteall_sessiontags, Event
      can :deleteall_speakerdata, Event
      can :deleteall_exhibitordata, Event
      can :deleteall_exhibitortags, Event
      can :deleteall_mappingdata, Event
      can :deleteall_eventconfigdata, Event
      can :deleteall_attendeedata, Event
      can :deleteall_attendeetags, Event
      can :deleteall_notificationdata, Event
      can :deleteall_home_buttondata, Event
      can :change_event, Event
      can :rooms_index, LocationMapping
      can :booths_index, LocationMapping
      can :send_data_update, Notification
      can :see_timestamps, User, :id => user.id
      can :display_message, Message
      can :unsubscribe, Message
      can :subscribe, Message
      can :update_coordinate, LocationMapping
      can :show_gallery_photos, Event
      can :upload_gallery_photos, Event
      can :destroy_game_and_survey_data_for_attendee, Attendee
      can :deliver_app_message, Attendee
      can :app_message, Attendee
      can :app_message_company_data, Attendee
      can :app_message_business_units_data, Attendee
      can :app_message_attendees_data, Attendee
      can :app_message_exhibitors_data, Attendee
      can :sessions_and_speakers_feedback, Feedback
      can :create_exhibitor_files_for_placeholders, Event
      can :add_exhibitor_files_to_placeholders, Event
      can :statistics, Event
      can :statistics_pdf, Event
      can :report_downloads, Event
      # can :grid_view,                                     SessionGridController
      # can :ajax_get_session_grid_settings,                SessionGridController
      # can :ajax_push_session_grid_settings,               SessionGridController
      # can :ajax_session_grid_autocomplete_data,           SessionGridController
      # can :ajax_session_grid_tags_only_autocomplete_data, SessionGridController
      # can :ajax_session_data,                             SessionGridController
      can :exhibitor_products_report, ExhibitorProduct
      can :remove_association, LocationMapping
      can :multiple_new, BoothOwner
      can :update_multiple_new, BoothOwner
      can :survey_wizard, :all
      can :client, :all
      can :toggle_unpublished, SessionsSpeaker
      can :exhibitor_surveys_report, :all
      can :video_visits_report, :all
      can :exhibitor_uncompleted_surveys_report, :all
      can :exhibitor_all_attendee_lead_report, :all
      can :new_subscribe_unsubscribe_settings, OrganizationSetting
      can :create_subscribe_unsubscribe_settings, OrganizationSetting

    elsif user.role? :trackowner
      can :manage,[Track,Subtrack,Session,Speaker,SpeakerFile,Exhibitor,LocationMapping,
                   LocationMappingType,EventMap,Attendee,SessionFile,SessionFileVersion,RoomLayout,SessionsAttendee]

      can :trackowner, :all

      can :toggle_unpublished, SessionsSpeaker

      can :refresh_external_api_import_script, Event
      # can :configure, Event # probably don't actually want this; but just while testing, not sure why I'm landing here at all
      can :change_event, Event
      can :rooms_index, LocationMapping
      can :booths_index, LocationMapping
      can :see_timestamps, User, :id => user.id
      can :display_message, Message
      can :unsubscribe, Message
      can :subscribe, Message
      can :update_coordinate, LocationMapping

    elsif user.role? :speaker
      can :manage, [SessionFile,SessionFileVersion,RoomLayout,SpeakerFile]
      can :display_message, Message
      can :unsubscribe, Message
      can :subscribe, Message
      can :change_event, Event

    elsif user.role? :exhibitor
      can :manage, [Exhibitor,ExhibitorProduct,ExhibitorFile,Survey,VideoView]
      can :display_message, Message
      can :unsubscribe, Message
      can :subscribe, Message
      can :change_event, Event
      can :survey_wizard, :all
      can :exhibitor_surveys_report, :all
      can :video_visits_report, :all
      can :exhibitor_uncompleted_surveys_report, :all
      can :exhibitor_all_attendee_lead_report, :all

    elsif user.role? :moderator
      can :change_event, Event

    elsif user.role? :partner
      can :change_event, Event
      can :download_attendees, Event
    elsif user.role? :member
      can :show, User
      can :show_event, User
      can :attendee_register, User
      can :attendee_register_submit, User
    
    elsif user.role? :attendee
      can :landing, User
      can :profile, User
      can :edit_profile, User
      can :update_profile, User
      can :my_orders, User
      can :download_invoice, User
    end
  end
end
