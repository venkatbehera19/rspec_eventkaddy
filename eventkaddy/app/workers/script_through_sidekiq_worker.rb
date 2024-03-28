class ScriptThroughSidekiqWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform(script_id, event_id, filename)
    script =  Script.find script_id
    job_id = script.create_job
    file_name = script.file_name
    script_path = "ek_scripts/external-api-imports"
    script_path = Rails.root.join("#{script_path}/#{file_name} \"#{script.event_id}\" \"#{job_id}\"")
    puts "Script path #{script_path}"
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{script_path} 2>&1")
    puts "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(job_id).update!(pid:pid)
    Process.detach pid

    event_timezone = script.event.timezone || "UTC"
    current_time_tz = DateTime.now.in_time_zone(event_timezone)
    utc_offset = current_time_tz.strftime("%z")
    run_till = script.run_till || DateTime.now + 7.days
    script_datetime = run_till.strftime("%d-%m-%Y %H:%M #{utc_offset}")
    script_time_tz = DateTime.parse(script_datetime).in_time_zone(event_timezone)

    if script_time_tz > current_time_tz
      script.run_script_at_intervals
    end
  end
end