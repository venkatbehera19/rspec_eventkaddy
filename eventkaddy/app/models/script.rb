class Script < ApplicationRecord
  belongs_to :script_type
  belongs_to :event
  validates :script_type, presence: true
  validates :button_label, presence: true
  

  def create_job
    job_name = self.button_label.downcase.gsub(/\s/, '-')
    job = Job.ajax_job_create_hash({event_id: self.event_id, name: job_name})
    return job[:job_id]
  end

  def run_script_at
    event_timezone = self.event.timezone || "UTC"
    current_time_tz = DateTime.now.in_time_zone(event_timezone)
    utc_offset = current_time_tz.strftime("%z")
    script_datetime = self.run_start_at.strftime("%d-%m-%Y %H:%M #{utc_offset}")
    script_time_tz = DateTime.parse(script_datetime).in_time_zone(event_timezone)

    if script_time_tz > current_time_tz
      time_diff_in_sec = script_time_tz.to_time - current_time_tz.to_time
    else
      time_diff_in_sec = (script_time_tz + 1.day).to_time - current_time_tz.to_time
    end
    self.call_to_worker(time_diff_in_sec, "start")
  end

  def call_to_worker(time, type)
    Sidekiq::ScheduledSet.new.each do |schedule|
      if (schedule.args[0] == self.id) && (schedule.args[2] == self.file_name)
        schedule.delete
      end
    end
    ScriptThroughSidekiqWorker.perform_in(time.seconds, self.id, self.event_id, self.file_name)
  end

  def run_script_at_intervals
    intervals = self.run_at_intervals
    if intervals
      if intervals.include? "hour"
        to_seconds = 1.hours.seconds
      elsif intervals.include? "min"
        to_seconds = 1.minutes.seconds
      end
      next_job_time = intervals.to_i * to_seconds
      self.call_to_worker(next_job_time, "intervals")
    end
  end

  def self.run_at_intervals
    ["10 min", "20 min", "30 min", "1 hour", "2 hour", "4 hour"]
  end
end

