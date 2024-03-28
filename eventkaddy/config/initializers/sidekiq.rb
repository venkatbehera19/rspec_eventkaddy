require 'sidekiq/web'
Sidekiq::Web.app_url = '/'

#sidekiq web UI security
# Sidekiq::Web.use(Rack::Auth::Basic, 'Application') do |username, password|
#   username == YAML.load_file('config/redis.yml')['sidekiq_username'] &&
#   password == YAML.load_file('config/redis.yml')['sidekiq_password']
# end

redis_db = YAML.load_file(File.join(Rails.root, 'config/redis.yml'))[Rails.env]

Sidekiq.configure_server do |config|
  config.redis = { url: "#{redis_db['host']}/#{redis_db['db']}" }

  # unique job middleware
  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end
end

# Sidekiq.configure_client do |config|
#   config.redis = { url: "#{redis_db['host']}/#{redis_db['db']}" }
# end
