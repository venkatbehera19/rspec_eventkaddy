Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, "736369142474-nqf2sk960t7pq72vtu8tfc2ab7pproc0.apps.googleusercontent.com","fWiqdlaGsrLO53BM1ndNgJ6k",
  {
    :access_type => 'offline',
    :prompt => 'consent',
    :select_account => true,
    :scope => 'userinfo.email, calendar.events'
  }  
end
OmniAuth.config.on_failure = EventRegistrationsController.action(:oauth_failure)