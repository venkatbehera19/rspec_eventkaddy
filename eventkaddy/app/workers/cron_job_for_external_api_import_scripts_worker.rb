require 'sidekiq-scheduler'

class CronJobForExternalApiImportScriptsWorker
  include Sidekiq::Worker
  def perform
    #Job.refresh_ym_attendees_2022_aysnc
    #Job.refresh_ym_exhibitors_2022_aysnc
  end
end