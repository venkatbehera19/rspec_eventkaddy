class AddMetaDataToTagsWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform(event_id)
    background_job = BackgroundJob.create(external_job_id: self.jid, entity_id: event_id, entity_type: 'Event', status: 'in_progress', purpose: "add_session_meta_data")
    begin
      Tag.add_all_session_meta_tag_data event_id
      background_job.update(status: 'done')
    rescue StandardError => e
      background_job.update(status: 'failed', fail_message: e.message, error_stack: e.backtrace.join("\n\t"))
    end
  end
end
