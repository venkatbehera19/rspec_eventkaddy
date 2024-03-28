###########################################
#Bootstrap script for creating table types
###########################################

# Tables are in alphabetical order.
# Find the type table you need to add a type to,
# and attach the appropriate values to the arrays.
# The values are paired according to their index.
# ie the first value of each array are for the same
# row. The second value of each array are for the
# next row, and so on.

# Useful shortcuts in sublime for editing this file:
#
# command + shift + l (add cursors to ends of selected lines)
# command + shift + arrow (select until end of lines)
# command + arrow (move cursors to ends or beginnings of lines)
# command + / (comment out selected lines)
# command + k, command + 2 (code fold lines indented 2 spaces; ie show all tables)
# command + k, command + 0 (unfold code)



require_relative './settings.rb' #config


#for active record usage
require 'active_record'
require_relative '../config/environment.rb' #load the rails 3 environment


ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",
	:host     => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#ActiveRecord::Base.logger = Logger.new(STDOUT) # Enable to show SQL queries in console

type_tables = [

	{table_name:"action_history_types",
		rows:[
			{id:1, name:"Bulk Deletion"      },
			{id:2, name:"Spreadsheet Upload" },
			{id:3, name:"Integration Pull"   },
			{id:4, name:"Other"              }
		]
	},

	{table_name:"app_badge_task_types",
		rows:[
			{id:1, name:"Sign In Badge Task"               },
			{id:2, name:"Session Favourite Badge Task"     },
			{id:3, name:"Exhibitor Favourite Badge Task"   },
			{id:4, name:"Scavenger Hunt Item Badge Task"   },
			{id:5, name:"CE Session Favourite Badge Task"  },
			{id:6, name:"iAttend CE Session Badge Task"    },
			{id:7, name:"Session Survey Badge Task"        },
			{id:8, name:"CE Session Survey Badge Task"     },
			{id:9, name:"Single Session Survey Badge Task" },
			{id:10,name:"Add Photo to Gallery Badge Task"  },
			{id:11,name:"Quiz Badge Task"                  },
			{id:12,name:"Survey Participation Badge Task"  },
			{id:13,name:"Scan Attendee Badge Task"         },
			{id:14,name:"QA Submission Badge Task"         },
			{id:15,name:"Session Feedback Badge Task"      },
			{id:16,name:"Add Profile Photo Badge Task"     },
			{id:17,name:"Like Photos Badge Task"           },
			# {id:16,name:"Lead Surveys Badge Task"          },
		]
	},
  
	{table_name:"app_image_sizes",
		rows:[
			{id:1, image_width:640,  image_height:100 },
			{id:2, image_width:1242, image_height:150 },
			{id:3, image_width:750,  image_height:100 },
			{id:4, image_width:1536, image_height:100 },
			{id:5, image_width:320,  image_height:80  },
			{id:6, image_width:480,  image_height:80  },
			{id:7, image_width:1250, image_height:80  },
			{id:8, image_width:40,   image_height:40  },
			{id:9, image_width:320,  image_height:50  },

			{id:10, image_width:640,  image_height:200 },
			{id:11, image_width:750,  image_height:200 },
			{id:12, image_width:1536, image_height:200 },
			{id:13, image_width:320,  image_height:160 },
			{id:14, image_width:1242, image_height:200 }
		]
	},

	{table_name:"app_image_types",
		rows:[
			{id:1, name:"banner" },
			{id:2, name:"center-header" },
			{id:3, name:"icon-header" },
			{id:4, name:"minimalist-mode-header" },
			{id:5, name:"minimalist-mode-footer" }
		]
	},

	{table_name:"attendee_gps_data_point_types",
		rows:[
			{id:1, name:"pedometer" }
		]
	},

	{table_name:"attendee_text_upload_types",
		rows:[
			{id:1, name:"note" },
			{id:2, name:"q&a"  }
		]
	},

	{table_name:"attendee_types",
		rows:[
			{id:1, name:"Standard Attendee" },
			{id:2, name:"Speaker"           },
			{id:3, name:"Guest"             },
			{id:4, name:"Exhibitor"         },
			{id:5, name:"Client"            },
			{id:6, name:"Moderator"         },
      # admin is for ease of testing / full accessibility, but in
      # development we should use real types to ensure no mistakes for real users
			{id:7, name:"Admin"             }
		]
	},

	{table_name:"av_list_items",
		rows:[
			{id:1,  name:"Microphones - Wireless Microphone (Lavalier)"     },
			{id:2,  name:"Microphones - Wireless Microphone (Handheld)"     },
			{id:3,  name:"Miscellaneous - Internet Connection"              },
			{id:4,  name:"Miscellaneous - Flip Chart with Pens"             },
			{id:5,  name:"Miscellaneous - Speaker laptop will be used"      },
			{id:6,  name:"Projectors/Screens - Additional Screen"           },
			{id:7,  name:"Projectors/Screens - Overhead Projector"          },
			{id:8,  name:"Miscellaneous - Other.  See Notes"                },
			{id:9,  name:"Laptop Selection"                                 },
			{id:10, name:"Additional Wireless Microphone"                   },
			{id:11, name:"Hardwired Lavaliere Microphone"                   },
			{id:12, name:"VGA Switcher (Needed to plug-in personal laptop)" },
			{id:13, name:"Digital Input Box (Used to project sound)"        },
			{id:14, name:"Handheld Wireless Microphone"                     },
			{id:15, name:"Other"                                            },
			{id:16, name:"Standard AV: Screen"                              },
			{id:17, name:"LCD Projector"                                    },
			{id:18, name:"Desktop Computer"                                 },
			{id:19, name:"Podium Mic"                                       },
			{id:20, name:"Wireless Lav Mic"                                 },
			{id:21, name:"Wireless Advancer/Laser Pointer"                  },
			{id:22, name:"Laptop Computer"                                  },
			{id:23, name:"Wireless Mic"                                     },
			{id:24, name:"Other AV Requirments - Please Stipulate"          },
			{id:25, name:"Q&A"                                              },
			{id:26, name:"Polling"                                          }
		]
	},

	{table_name:"booth_size_types",
		rows:[
			{id:1, name:"big square"              },
			{id:2, name:"vertical half of square" },
			{id:3, name:"small square"            }
		]
	},

	{table_name:"custom_list_types",
		rows:[
			{id:1,  name:"Extras",                 user_made:false },
			{id:2,  name:"Help",                   user_made:false },
			{id:3,  name:"Info",                   user_made:false },
			{id:4,  name:"FAQ",                    user_made:false },
			{id:5,  name:"Sponsors",               user_made:false },
			{id:6,  name:"Messaging",              user_made:true  },
			{id:7,  name:"Activity",               user_made:true  },
			{id:8,  name:"Social",                 user_made:false },
			{id:9,  name:"WVC TV",                 user_made:true  },
			{id:10, name:"Featured",               user_made:true  },
			{id:11, name:"Contact Us",             user_made:true  },
			{id:12, name:"Conference Evaluations", user_made:true  },
			{id:13, name:"Evening Events",         user_made:true  },
			{id:14, name:"Raffles",                user_made:true  },
			{id:15, name:"Travel Info",            user_made:true  },
			{id:16, name:"Registration Hours",     user_made:true  },
			{id:17, name:"Privacy Policy",         user_made:true  },
			{id:18, name:"Notes",                  user_made:true  },
			{id:19, name:"Settings",               user_made:true  },
			{id:20, name:"QR Scanner",             user_made:true  },
			{id:21, name:"Convention Newspaper",   user_made:true  },
			{id:22, name:"Extras",                 user_made:true  },
			{id:23, name:"Transportation2",        user_made:true  },
			{id:24, name:"Other Happenings",       user_made:true  },
			{id:25, name:"Help",                   user_made:true  },
			{id:26, name:"Sponsors",               user_made:true  },
			{id:27, name:"Foundation",             user_made:true  },
			{id:28, name:"Proceedings Notes",      user_made:true  },
			{id:29, name:"Social",                 user_made:true  },
			{id:30, name:"Polling",                user_made:true  },
			{id:31, name:"Other Happenings",       user_made:true  },
			{id:32, name:"Help",                   user_made:true  },
			{id:33, name:"Sponsors",               user_made:true  },
			{id:34, name:"Foundation",             user_made:true  },
			{id:35, name:"Proceedings Notes",      user_made:true  },
			{id:36, name:"Social",                 user_made:true  },
			{id:37, name:"Extras",                 user_made:true  },
			{id:38, name:"Social",                 user_made:true  },
			{id:39, name:"FAQ",                    user_made:true  }
		]
	},

	{table_name:"device_app_image_sizes",
		rows:[
			{id:1, device_type_id:7,   app_image_type_id:1, app_image_size_id:1 },
			{id:2, device_type_id:4,   app_image_type_id:1, app_image_size_id:4 },
			{id:3, device_type_id:8,   app_image_type_id:1, app_image_size_id:3 },
			{id:4, device_type_id:9,   app_image_type_id:1, app_image_size_id:2 },
			{id:5, device_type_id:7,   app_image_type_id:2, app_image_size_id:5 },
			{id:6, device_type_id:4,   app_image_type_id:2, app_image_size_id:7 },
			{id:7, device_type_id:8,   app_image_type_id:2, app_image_size_id:5 },
			{id:8, device_type_id:9,   app_image_type_id:2, app_image_size_id:6 },
			{id:9, device_type_id:10,  app_image_type_id:1, app_image_size_id:9 },
			{id:10, device_type_id:12, app_image_type_id:1, app_image_size_id:3 },
			{id:11, device_type_id:12, app_image_type_id:2, app_image_size_id:5 },

      # minimalist-mode-header
			{id:12, device_type_id:7,  app_image_type_id:4, app_image_size_id:10 }, # iPhone 4_5    640x200
			{id:13, device_type_id:4,  app_image_type_id:4, app_image_size_id:12 }, # iOS Tablet    1536x200
			{id:14, device_type_id:8,  app_image_type_id:4, app_image_size_id:11 }, # iPhone 6      750x200
			{id:15, device_type_id:9,  app_image_type_id:4, app_image_size_id:14 }, # iPhone 6 Plus 1242x200
			{id:16, device_type_id:10, app_image_type_id:4, app_image_size_id:13 }, # Mobile Web    320x160
			{id:17, device_type_id:12, app_image_type_id:4, app_image_size_id:11 }, # iPhone X      750x200
      # minimalist-mode-footer
			{id:18, device_type_id:7,  app_image_type_id:5, app_image_size_id:1 }, # iPhone 4_5    640x100
			{id:19, device_type_id:4,  app_image_type_id:5, app_image_size_id:4 }, # iOS Tablet    1536x100
			{id:20, device_type_id:8,  app_image_type_id:5, app_image_size_id:3 }, # iPhone 6      750x100
			{id:21, device_type_id:9,  app_image_type_id:5, app_image_size_id:2 }, # iPhone 6 Plus 1242x100
			{id:22, device_type_id:10, app_image_type_id:5, app_image_size_id:9 }, # Mobile Web    320x80
			{id:23, device_type_id:12, app_image_type_id:5, app_image_size_id:3 }, # iPhone X      750x100
		]
	},

	{table_name:"device_types",
		rows:[
			{id:1, parent_id:0, leaf:0, name:"Phone"         },
			{id:2, parent_id:0, leaf:0, name:"Tablet"        },
			{id:3, parent_id:1, leaf:0, name:"iOS Phone"     },
			{id:4, parent_id:2, leaf:1, name:"iOS Tablet"    },
			{id:5, parent_id:1, leaf:0, name:"Android Phone" },
			{id:6, parent_id:1, leaf:0, name:"Windows Phone" },
			{id:7, parent_id:3, leaf:1, name:"iPhone 4_5"    },
			{id:8, parent_id:3, leaf:1, name:"iPhone 6"      },
			{id:9, parent_id:3, leaf:1, name:"iPhone 6 Plus" },
			{id:10, parent_id:0, leaf:1, name:"Mobile Web"   },
			{id:11, parent_id:0, leaf:1, name:"Desktop"      },
			{id:12, parent_id:3, leaf:1, name:"iPhone X"     }
		]
	},

	{table_name:"domain_types",
		rows:[
			{id:1, name:"cms"          },
			{id:2, name:"video_portal" },
			{id:3, name:"mobile_site"  }
		]
	},

	{table_name:"email_types",
		rows:[
			{id:1, name:'send_password'}
		]
	},

	{table_name:"event_file_types",
		rows:[
			{id:1,  name:"speaker_photo"           },
			{id:2,  name:"map"                     },
			{id:3,  name:"event_logo"              },
			{id:4,  name:"exhibitor_logo"          },
			{id:5,  name:"enhanced_listing_image"  },
			{id:6,  name:"session_link_file"       },
			{id:7,  name:"spreadsheet_file"        },
			{id:8,  name:"home_button_icon"        },
			{id:9,  name:"home_button_entry_icon"  },
			{id:10, name:"speaker_pdf"             },
			{id:11, name:"speaker_cv"              },
			{id:12, name:"speaker_fd"              },
			{id:13, name:"session_file"            },
			{id:14, name:"room_layout"             },
			{id:15, name:"speaker_pdf_upload"      },
			{id:16, name:"event_message_image"     },
			{id:17, name:"exhibitor_message_image" },
			{id:18, name:"speaker_pdf_no_sign"     },
			{id:19, name:"tablet_banner_ad"        },
			{id:20, name:"phone_banner_ad"         },
			{id:21, name:"home_button_entry_image" },
			{id:22, name:"exhibitor_file"          },
			{id:23, name:"pg-camera"               },
			{id:24, name:"pg-photobooth"           },
			{id:25, name:"diy"                     },
			{id:26, name:"product_image"           },
			{id:27, name:"qr_code"                 },
			{id:28, name:"app-image"               },
			{id:29, name:"video_portal_image"      },
			{id:30, name:"scavenger_hunt_image"    },
			{id:31, name:"session_thumbnail"       },
			{id:32, name:"attendee_photo"          },
			{id:33, name:"app_badge_image"         },
			{id:34, name:"app_badge_task_image"    }
		]
	},

	{table_name:"exhibitor_file_types",
		rows:[
			{id:1, name:"message_image" },
			{id:2, name:"exhibitor_document"}
		]
	},

	{table_name:"hidden_notification_types",
		rows:[
      {id:1, name:"New Data"},
      {id:2, name:"EK_DATA_UPDATE"},
      {id:3, name:"EK_DATA_UPDATE_AND_RESET"},
      {id:4, name:"EK_FORCE_LOGOUT"},
      {id:5, name:"EK_TOGGLE_ON_CE_CREDITS"},
      {id:6, name:"EK_TOGGLE_OFF_CE_CREDITS"},
      {id:7, name:"SWITCHING_TO_SECONDARY_SERVER"},
      {id:8, name:"EK_FORCE_SETTINGS_REPULL"}

		]
	},

	{table_name:"home_button_entry_types",
		rows:[
			{id:1,  name:"Info"                   },
			{id:2,  name:"Help"                   },
			{id:3,  name:"WVC%20Live!"            },
			{id:4,  name:"Extras"                 },
			{id:5,  name:"General"                },
			{id:6,  name:"Sponsors"               },
			{id:7,  name:"Speakers"               },
			{id:8,  name:"Innovation%20Booths"    },
			{id:9,  name:"Newspaper"              },
			{id:10, name:"CE%20Info"              },
			{id:11, name:"Executive%20Welcome"    },
			{id:12, name:"Social%20Selling"       },
			{id:13, name:"Thought%20Leadership"   },
			{id:14, name:"Meeting%20Logistics"    },
			{id:15, name:"Smart%20Booths"         },
			{id:16, name:"Calendar%20of%20Events" },
			{id:17, name:"Proceeding%20Notes"     },
			{id:18, name:"Foundation"             },
			{id:19, name:"Other%20Happenings"     },
			{id:20, name:"Surveys"                },
			{id:21, name:"CNS"                    },
			{id:22, name:"ISQua"                  },
			{id:23, name:"Demo Booths"            },
			{id:24, name:"Conference Evaluation"  },
			{id:25, name:"Evening"                },
			{id:26, name:"Raffles"                },
			{id:27, name:"Registration"           },
			{id:28, name:"Privacy"                },
			{id:29, name:"Contact"                },
			{id:30, name:"Zip"                    }
		]
	},

	{table_name:"home_button_types",
		rows:[
			{id:1,  name:"Sessions",                      standard:true   },
			{id:2,  name:"Speakers",                      standard:true   },
			{id:3,  name:"Exhibitors",                    standard:true   },
			{id:4,  name:"Maps",                          standard:true   },
			{id:5,  name:"Notifications",                 standard:true   },
			{id:6,  name:"Favourites",                    standard:true   },
			{id:7,  name:"Settings",                      standard:true   },
			{id:8,  name:"Social",                        standard:true   },
			{id:9,  name:"Custom List",                   standard:false  },
			{id:10, name:"Attendees",                     standard:true   },
			{id:11, name:"Notes",                         standard:true   },
			{id:12, name:"Messaging",                     standard:true   },
			{id:13, name:"Photo",                         standard:false  },
			{id:14, name:"Whats On Now",                  standard:false  },
			{id:15, name:"External",                      standard:false  }, #skip 16, because data on production already skips it.
			{id:17, name:"External Popup",                standard:false  },
			{id:18, name:"Game",                          standard:false  },
			{id:19, name:"QA Sessions",                   standard:false  },
			{id:20, name:"Gallery Photo Uploader",        standard:false  },
			{id:21, name:"Exhibitor Game",                standard:false  },
			{id:22, name:"Photo Gallery",                 standard:false  },
			{id:23, name:"External Link",                 standard:false  },
			{id:24, name:"Barcode Scanner",               standard:false  },
			{id:25, name:"Attendee Profile",              standard:false  },
			{id:26, name:"Daily Questions",               standard:false  },
			{id:27, name:"Scavenger Hunt",                standard:false  },
			{id:28, name:"Survey",                        standard:false  },
			{id:29, name:"Gallery",                       standard:false  },
			{id:30, name:"CE Sessions",                   standard:false  },
			{id:31, name:"Attendee Scanner",              standard:false  },
			{id:32, name:"Session Recommendations",       standard:false  },
			{id:33, name:"Exhibitor Recommendations",     standard:false  },
      {id:34, name:"Session Attendance QR Scanner", standard: false },
      {id:35, name:"Exhibitor Leads QR Scanner",    standard: false },
      {id:36, name:"Remote Redirect",               standard: false }

		]
	},

	{table_name:"link_types",
		rows:[
			{id:1, link_type:"Conference Note" },
			{id:2, link_type:"Survey"          },
			{id:3, link_type:"Video"           },
			{id:4, link_type:"PDF"             }
		]
	},

	{table_name:"location_mapping_types",
		rows:[
			{id:1, type_name: "Room"  },
			{id:2, type_name: "Booth" }
		]
	},

	{table_name:"map_types",
		rows:[
			{id:1, map_type: "Session Map"           },
			{id:2, map_type: "Exhibitor Map"         },
			{id:3, map_type: "Other"                 },
			{id:4, map_type: "Interactive Map"       },
			{id:5, map_type: "Convention Center Map" },
			{id:6, map_type: "Hotel Map"             }
		]
	},

	{table_name:"message_types",
		rows:[
			{id:1, name:"for_speakers"                         },
			{id:2, name:"for_exhibitors"                       },
			{id:3, name:"for_speakers_and_exhibitors"          },
			{id:4, name:"to_speakers_with_incomplete_profiles" }
		]
	},

	{table_name:"mobile_web_setting_types",
		rows:[
			{id:1,   name:"title",                              default:".: Event Name :." },
			{id:2,   name:"background_image",                   default:"url" },
			{id:3,   name:"text_hilite_color",                  default:"#ffffff" },
			{id:4,   name:"link_color",                         default:"#ffffff" },
			{id:5,   name:"visited_link_color",                 default:"#ffffff" },
			{id:6,   name:"g_analytics_web",                    default:"394050" },
			{id:7,   name:"g_analytics_app",                    default:"340393" },
			{id:8,   name:"login_mode",                         default:"simple" },
			{id:9,   name:"background_color",                   default:"#ffffff,#ffffff" },
			{id:10,  name:"session_code_visible",               default:"0" },
			{id:11,  name:"external_survey",                    default:"0" },
			{id:12,  name:"attend_button_visible",              default:"0" },
			{id:13,  name:"feedback",                           default:"0" },
			{id:14,  name:"feedback_speaker",                   default:"0" },
			{id:15,  name:"session_button_days",                default:"Days" },
			{id:16,  name:"session_button_tracks",              default:"Tracks" },
			{id:17,  name:"session_button_speakers",            default:"Speakers" },
			{id:18,  name:"session_button_sponsors",            default:"Sponsors" },
			{id:19,  name:"session_button_audience",            default:"Audience" },
			{id:20,  name:"session_button_program",             default:"Program Type" },
			{id:21,  name:"session_button_promo",               default:"Featured" },
			{id:22,  name:"exhibitor_button_directory",         default:"Directory" },
			{id:23,  name:"exhibitor_button_category",          default:"Categories" },
			{id:24,  name:"exhibitor_button_booths",            default:"Booths" },
			{id:25,  name:"attendee_button_directory",          default:"Directory" },
			{id:26,  name:"attendee_button_bu",                 default:"Business Units" },
			{id:27,  name:"attendee_button_category",           default:"Filters" },
			{id:28,  name:"header_home_color",                  default:"#ffffff" },
			{id:29,  name:"header_home_icon",                   default:"url" },
			{id:30,  name:"header_back_color",                  default:"#ffffff" },
			{id:31,  name:"header_back_icon",                   default:"url" },
			{id:32,  name:"header_grid_color",                  default:"#ffffff" },
			{id:33,  name:"header_myagenda_icon",               default:"url" },
			{id:34,  name:"header_myagenda_color",              default:"#ffffff" },
			{id:35,  name:"banner_ad_timing",                   default:"3" },
			{id:36,  name:"header_grid_icon",                   default:"url" },
			{id:37,  name:"tag_list_visible",                   default:"1" },
			{id:38,  name:"tag_list_hierarchy_depth",           default:"2" },
			{id:39,  name:"session_my_agenda_button_color",     default:"#ffffff,#000000" },
			{id:40,  name:"session_note_button_color",          default:"#ffffff,#000000" },
			{id:41,  name:"session_qa_button_color",            default:"#ffffff,#000000" },
			{id:42,  name:"session_map_button_color",           default:"#ffffff,#000000" },
			{id:43,  name:"session_survey_button_color",        default:"#ffffff,#000000" },
			{id:44,  name:"session_poll_button_color",          default:"#ffffff,#000000" },
			{id:45,  name:"session_ce_button_color",            default:"#ffffff,#000000" },
			{id:46,  name:"session_calendar_button_color",      default:"#ffffff,#000000" },
			{id:47,  name:"session_speakers_label",             default:"Speaker(s)" },
			{id:48,  name:"session_description_label",          default:"Description" },
			{id:49,  name:"session_learning_objective_label",   default:"Learning Objectives" },
			{id:50,  name:"session_presentation_info_label",    default:"Presentation Info" },
			{id:51,  name:"session_files_label",                default:"File(s)" },
			{id:52,  name:"session_videos_label",               default:"Video(s)" },
			{id:53,  name:"login_username_label",               default:"Email" },
			{id:54,  name:"login_password_label",               default:"Password" },
			{id:55,  name:"login_forgot_password_label",        default:"Forgot password?" },
			{id:56,  name:"login_header",                       default:"header text" },
			{id:57,  name:"login_footer",                       default:"footer text" },
			{id:58,  name:"exhibitor_favourite_button_color",   default:"#23b7bb" },
			{id:59,  name:"exhibitor_map_button_color",         default:"#23b7bb" },
			{id:60,  name:"exhibitor_note_button_color",        default:"#ffffff" },
			{id:61,  name:"exhibitor_message_button_color",     default:"#ffffff" },
			{id:62,  name:"exhibitor_description_label",        default:"Description" },
			{id:63,  name:"exhibitor_contact_label",            default:"Contact" },
			{id:64,  name:"exhibitor_misc_label",               default:"Misc" },
			{id:65,  name:"attendee_message_button_color",      default:"#ffffff" },
			{id:66,  name:"attendee_favourite_button_color",    default:"#ffffff" },
			{id:67,  name:"attendee_note_button_color",         default:"#ffffff" },
			{id:68,  name:"attendee_contact_label",             default:"Contact Info" },
			{id:69,  name:"attendee_description_label",         default:"Description" },
			{id:70,  name:"header_logo_url",                    default:"url" },
			{id:71,  name:"print_myagenda_label",               default:"Print My Agenda" },
			{id:72,  name:"print_mycecredit_label",             default:"Print My CE Credits" },
			{id:73,  name:"attendee_messaging",                 default:"0" },
			{id:75,  name:"attendee_custom_filter_1",           default:"0" },
			{id:76,  name:"attendee_custom_filter_2",           default:"0" },
			{id:77,  name:"attendee_custom_filter_3",           default:"0" },
			{id:78,  name:"attendee_email_visible",             default:"0" },
			{id:79,  name:"attendee_list_simple",               default:"0" },
			{id:80,  name:"exhibitor_list_simple",              default:"0" },
			{id:81,  name:"session_list_simple",                default:"0" },
			{id:82,  name:"exhibitor_email_visible",            default:"0" },
			{id:83,  name:"speaker_email_visible",              default:"0" },
			{id:84,  name:"exhibitor_messaging",                default:"0" },
			{id:85,  name:"login_help_text",                    default:"html string" },
			{id:86,  name:"room_label",                         default:"Room: " },
			{id:87,  name:"booth_label",                        default:"Booth: " },
			{id:88,  name:"header_grid_icon_color",             default:"#ffffff" },
			{id:89,  name:"header_background_color",            default:"#222222,#222222" },
			{id:90,  name:"ce_active_start_date",               default:"2017-01-01" },
			{id:91,  name:"registration_url",                   default:"url" },
			{id:92,  name:"help",                               default:"text" },
			{id:93,  name:"session_button_tags",                default:"Tags" },
			{id:94,  name:"home_icon_font_color",               default:"#ffffff" },
			{id:95,  name:"header_home_login_url",              default:"url" },
			{id:96,  name:"header_home_login_color",            default:"#ffffff" },
			{id:97,  name:"header_home_logout_url",             default:"url" },
			{id:98,  name:"header_home_logout_color",           default:"#ffffff" },
			{id:99,  name:"session_list_tracksubtrack_visible", default:"1" },
			{id:100, name:"below_header_background_color",      default:"#222222,#222222" },
			{id:101, name:"bannerad_background_color",          default:"#222222,#222222" },
			{id:102, name:"myagenda_exhibitor_visible",         default:"1" },
			{id:103, name:"interactive_map_active",             default:"1" }
		]
	},

	{table_name:"program_types",
		rows:[
			{id:1,  name:"Lecture"              },
			{id:2,  name:"Industry Lunch"       },
			{id:3,  name:"Symposium"            },
			{id:4,  name:"Industry Breakfast"   },
			{id:5,  name:"Workshop"             },
			{id:6,  name:"Special Presentation" },
			{id:7,  name:"Lunch & Learn"        },
			{id:8,  name:"Hands-on Lab"         },
			{id:9,  name:"Abstract"             },
			{id:10, name:"Presentation"         },
			{id:11, name:"Invited Abstract"     },
			{id:12, name:"Poster"               },
			{id:13, name:"1.0"                  },
			{id:14, name:"0.5"                  },
			{id:15, name:"0.75"                 },
			{id:16, name:"0.25"                 },
			{id:17, name:"1.5"                  },
			{id:18, name:"5.0"                  },
			{id:19, name:"8.0"                  },
			{id:20, name:"4.0"                  },
			{id:21, name:"7.0"                  },
			{id:22, name:"3.0"                  },
			{id:23, name:"16.0"                 },
			{id:24, name:"2.0"                  }
		]
	},

	{table_name:"question_types",
		rows:[
			{id:1, name: "Multiple Choice"        },
			{id:2, name: "Long Form"              },
			{id:3, name: "Star Rating"            },
			{id:4, name: "Multiple Select"        },
			{id:5, name: "Autocomplete Exhibitor" }

  # multiple select exhibitor type? what do I want for this. it's a text field
  # with autocomplete and validation. client really doesn't put anything in
  # besides the question.question column. It can't be just a regular multiple
  # select, because that would require lots of extra logic and it's not really
  # that anyway
  #
  # Does an autocomplete type make sense? or at least, is Autocomplete
  # Exhibitor a good name for this field?
  #
  # We have question type names, but only two are actually listed in the _js
  # file. weird. It looks like they were used in an original design, but not
  # anymore
		]
	},

	{table_name:"recommendation_persistence_types",
		rows:[
			{id:1, name: "Permenant" },
			{id:2, name: "Daily"     }
		]
	},

	{table_name:"recommendation_source_types",
		rows:[
			{id:1, name: "CMS" },
			{id:2, name: "FISH"}
		]
	},

	{table_name:"record_types",
		rows:[
			{id:1, record_type: "cam+gfx+audio" },
			{id:2, record_type: "gfx+audio"     },
			{id:3, record_type: "audio"         },
			{id:4, record_type: "not set"       }
		]
	},

	{table_name:"requirement_types",
		rows:[
			{id:1,  name:"company",              requirement_for:"speaker" },
			{id:2,  name:"biography",            requirement_for:"speaker" },
			{id:3,  name:"photo_event_file_id",  requirement_for:"speaker" },
			{id:4,  name:"address1",             requirement_for:"speaker" },
			{id:5,  name:"city",                 requirement_for:"speaker" },
			{id:6,  name:"state",                requirement_for:"speaker" },
			{id:7,  name:"country",              requirement_for:"speaker" },
			{id:8,  name:"zip",                  requirement_for:"speaker" },
			{id:9,  name:"work_phone",           requirement_for:"speaker" },
			{id:10, name:"mobile_phone",         requirement_for:"speaker" },
			{id:11, name:"fax",                  requirement_for:"speaker" },
			{id:12, name:"financial_disclosure", requirement_for:"speaker" },
			{id:13, name:"cv_event_file_id",     requirement_for:"speaker" },
			{id:14, name:"fd_tax_id",            requirement_for:"speaker" },
			{id:15, name:"fd_pay_to",            requirement_for:"speaker" },
			{id:16, name:"fd_street_address",    requirement_for:"speaker" },
			{id:17, name:"fd_city",              requirement_for:"speaker" },
			{id:18, name:"fd_state",             requirement_for:"speaker" },
			{id:19, name:"fd_zip",               requirement_for:"speaker" }
		]
	},

	{table_name:"roles",
		rows:[
			{id:1, name:"SuperAdmin" },
			{id:2, name:"Client"     },
			{id:3, name:"Speaker"    },
			{id:4, name:"Exhibitor"  },
			{id:5, name:"TrackOwner" },
			{id:6, name:"Moderator"  },
			{id:7, name:"DiyClient"  },
      {id:8, name:"Partner"    }
		]
	},

	{table_name:"room_layout_configurations",
		rows:[
			{id:1, name:"Classroom"       },
			{id:2, name:"Crescent Rounds" },
			{id:3, name:"Exhibit"         },
			{id:4, name:"Hollow Square"   },
			{id:5, name:"Rounds"          },
			{id:6, name:"Theatre"         },
			{id:7, name:"U-Shape"         }
		]
	},

	{table_name:"scavenger_hunt_item_types",
		rows:[
      { id:1, name:"Input Field"      },
      { id:2, name:"QR Code"          },
      { id:3, name:"QR Code or Input" },
      { id:4, name:"Flare Photo"      }
		]
	},

	{table_name:"session_file_types",
		rows:[
			{id:1, name:"Conference Note" },
			{id:2, name:"PowerPoint"      },
			{id:3, name:"Media"           }
		]
	},

	{table_name:"setting_types",
		rows:[
			{id:1, name:"video_portal_booleans"     },
			{id:2, name:"video_portal_strings"      },
			{id:3, name:"cordova_booleans"          },
			{id:4, name:"cordova_strings"           },
			{id:5, name:"cms_settings"              },
			{id:6, name:"exhibitor_portal_settings" },
			{id:7, name:"guest_view_settings"       },
			{id:8, name:"cordova_ekm_settings"      },
			{id:9, name:"cordova_window_settings"   },
			{id:10, name:"speaker_portal_settings" },
		]
	},

	{table_name:"speaker_file_types",
		rows:[
			{id:1, name:"signed document" }
		]
	},

	{table_name:"speaker_types",
		rows:[
			{id:1, speaker_type:"Primary Presenter"   },
			{id:2, speaker_type:"Presenter"           },
			{id:3, speaker_type:"Coordinator"         },
			{id:4, speaker_type:"Tutor"               },
			{id:5, speaker_type:"Instructor"          },
			{id:6, speaker_type:"Moderator"           },
			{id:7, speaker_type:"Topic Coordinator"   },
			{id:8, speaker_type:"Symposium Organizer" }
		]
	},

	{table_name:"sponsor_level_types",
		rows:[
			{id:1, sponsor_type:"Platinum"             },
			{id:2, sponsor_type:"Gold"                 },
			{id:3, sponsor_type:"Silver"               },
			{id:4, sponsor_type:"Bronze"               },
			{id:5, sponsor_type:"Executive"            },
			{id:6, sponsor_type:"General"              },
			{id:7, sponsor_type:"Hands-On Lab Sponsor" },
			{id:8, sponsor_type:"Diamond"              },
			{id:9, sponsor_type:"Ruby"                 },
			{id:10, sponsor_type:"Sapphire"            },
			{id:11, sponsor_type:"Emerald"             },
			{id:12, sponsor_type:"Topaz"               }
		]
	},

	{table_name:"survey_types",
		rows:[
			{id:1, name:"Global Poll"      },
			{id:2, name:"Daily Questions"  },
			{id:3, name:"Session Survey"   },
			{id:4, name:"Attendee Survey"  }, # didn't mean to make this type; could be useful one day
			{id:5, name:"Exhibitor Survey" }, # another misnamed type that isn't really used
			{id:6, name:"Exhibitor Lead Survey" }  # this is a survey that belongs to an exhibitor, about an attendee
		]
	},

	{table_name:"tab_types",
		rows:[
			{id:1,  default_name:"Welcome",                controller_action:"checklist",             portal:"speaker"    },
			{id:2,  default_name:"Contact Details",        controller_action:"show_contactinfo",      portal:"speaker"    },
			{id:3,  default_name:"Travel & Lodging",       controller_action:"show_travel_detail",    portal:"speaker"    },
			{id:4,  default_name:"Sessions",               controller_action:"sessions",              portal:"speaker"    },
			{id:5,  default_name:"Payment Details",        controller_action:"show_payment_detail",   portal:"speaker"    },
			{id:6,  default_name:"Messages",               controller_action:"messages",              portal:"speaker"    },
			{id:7,  default_name:"PDF Downloads",          controller_action:"download_pdf",          portal:"speaker"    },
			{id:8,  default_name:"Welcome",                controller_action:"landing",               portal:"exhibitor"  },
			{id:9,  default_name:"Exhibitor Details",      controller_action:"show_exhibitordetails", portal:"exhibitor"  },
			{id:10, default_name:"Conference Messages",    controller_action:"messages",              portal:"exhibitor"  },
			{id:11, default_name:"Exhibitor Page Content", controller_action:"edit_custom_content",   portal:"exhibitor"  },
			{id:12, default_name:"Welcome",                controller_action:"landing",               portal:"trackowner" },
			{id:13, default_name:"Sessions",               controller_action:"sessions",              portal:"trackowner" },
			{id:14, default_name:"Speakers",               controller_action:"speakers",              portal:"trackowner" },
			{id:15, default_name:"Session Notes",          controller_action:"session_files",         portal:"trackowner" },
			{id:16, default_name:"FAQ",                    controller_action:"faq",                   portal:"speaker"    },
			{id:17, default_name:"Exhibitor Product",      controller_action:"exhibitor_products",    portal:"exhibitor"  },
			{id:18, default_name:"Exhibitor Tags",         controller_action:"edit_tags",             portal:"exhibitor"  },
			{id:19, default_name:"Exhibitor Preview",         controller_action:"preview",             portal:"exhibitor"  }
		]
	},

	{table_name:"tag_types",
		rows:[
			{id:1, name:"session"          },
			{id:2, name:"exhibitor"        },
			{id:3, name:"session-audience" },
			{id:4, name:"attendee"         }
		]
	},

	{table_name:"template_types",
		rows:[
			{id:1, name:"speaker_email_password_template"   },
			{id:2, name:"attendee_email_password_template"  },
			{id:3, name:"exhibitor_email_password_template" },
			{id:4, name:"attendee_email_confirmation_template" }
		]
	},


	{table_name:"users_roles",
		rows:[
			{id:1, role_id:1, user_id:1 }
		]
	},

	{table_name:"video_portal_image_types",
		rows:[
			{id:1, name:'Single Page App Banner' },
			{id:2, name:'Navigation Logo'        },
			{id:3, name:'Top Footer'             },
			{id:4, name:'Bottom Footer'          }
		]
	},

	{table_name:"attendee_scan_types",
		rows:[
			{id:1, name:'attendee_to_attendee'  },
			{id:2, name:'session'               }, # unused, but would be an attendee scanning a session
			{id:3, name:'exhibitor'             }, # ditto
			{id:4, name:'location_mapping'      }, # ditto
			{id:5, name:'iattend_update'        }, # a moderator type attendee scanning an attendee
			{id:6, name:'exhibitor_lead_survey' }  # an exhibitor type attendee scanning an attendee
		]
	}
]

def row_has_changed?(row, table_name, record)
	columns_ary  = []
	data_from_db = record.as_json[table_name]
	data_from_db.each {|k, v| columns_ary << k}

	columns_ary.each do |c|
		return true if row.as_json[c] != data_from_db[c] && c != 'created_at' && c != 'updated_at'
	end
	return false
end

new_rows = []
changed_rows = []

type_tables.each do |table|

	puts "------ Adding rows for: #{table[:table_name]} -------"

	if ActiveRecord::Base.connection.table_exists? table[:table_name]

		model = table[:table_name].singularize.classify.constantize

		table[:rows].each do |row|
			records = model.where(id:row[:id])
			if records.length === 0
				puts "Creating row for table #{table[:table_name]}"
				puts row.inspect.yellow
				new_rows << row.inspect
				puts "New row.".yellow
				model.create(row)
			else
				puts "Updating row for table #{table[:table_name]}"
				old_hash = records[0].as_json[table[:table_name].singularize]
				old_hash.delete('created_at'); old_hash.delete('updated_at');

				if row_has_changed?(row, table[:table_name].singularize, records[0])
					puts "old: " + old_hash.sort.inspect.yellow
					puts "new: " + row.as_json.sort.inspect.yellow
					print "The above type is different. Is it okay to update? (y update, any other key to abort)".yellow
					input = gets.strip
					if input == 'y'
						records.first.update!(row)
						changed_rows << row.as_json.sort.inspect
					else
						abort
					end
				else
					puts "old: " + old_hash.sort.inspect.green
					puts "new: " + row.as_json.sort.inspect.green
					puts "No change.".green
				end
			end
		end
	else
		puts "Table #{table[:table_name]} does not exist. Try running 'rake db:migrate'"
	end
end

puts 'New Rows:'.yellow
new_rows.each {|r| puts r.green }
puts 'Changed Rows:'.yellow
changed_rows.each {|r| puts r.green }
