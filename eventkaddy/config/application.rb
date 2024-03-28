require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Eventkaddy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0
    # config.action_dispatch.default_headers[:'X-Frame-Options'] = "ALLOW-FROM http://localhost:3001"


    # if you are using thin, then you can add as many Faye servers as you want to the Rails middleware stack like this
    # config.middleware.use FayeRails::Middleware, mount: '/faye', :timeout => 25 do
    #   map '/session/*' => PollsStreamController
    #   map default: :block
    # end
    ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
      html_tag.html_safe
    end

    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}', '{**}')]
    # config.autoload_paths += Dir[Rails.root.join('app', 'controllers', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'controllers', '**', '*.rb')]
    config.autoload_paths += Dir[Rails.root.join('app', 'domain_objects', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'services', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'services', '{**}', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'workers')]
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths += %W(#{Rails.root.join('app', 'workers')})
    #override the layout for (devise-based) public access pages
    config.to_prepare do
      Devise::SessionsController.layout "application_2013"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "superadmin_2013"   : "application_2013" }
      Devise::ConfirmationsController.layout "application_2013"
      Devise::UnlocksController.layout "application_2013"
      Devise::PasswordsController.layout "application_2013"
    end
    #needed for Devise (user auth module)
  	config.action_mailer.default_url_options = { :host => 'dev.eventkaddy.net', :protocol => 'https' }
  end
end
