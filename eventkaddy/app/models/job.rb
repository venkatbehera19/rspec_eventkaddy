class Job < ApplicationRecord
  # attr_accessible :error_message, :event_id, :name, :row, :status, :total_rows, :warnings, :original_file, :backtrace, :pid, :info

  def run_job_in_background cmd
    puts cmd.inspect.red
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
    job.update!(pid:pid)
    Process.detach pid
    {:status => true, job_id: job_id}
  end

  def self.refresh_ym_attendees_2022_aysnc
    script = Script.find_by(event_id: 280,button_label:"Refresh Attendees")
    file_name = script.file_name
    job = Job.create(name: "refresh-attendees",row: 0,event_id: 280,status:'Starting...')
    script_path = "ek_scripts/external-api-imports"
    script_path = Rails.root.join("#{script_path}/#{file_name} \"280\" \"#{job.id}\" \"refresh\" \"standard_attendee\"")
    run_job_with_sidekiq_cron script_path
  end

  def refresh_ym_exhibitors_2022_aysnc
    script = Script.find_by(event_id: 280,button_label:"Refresh Exhibitors")
    file_name = script.file_name
    job = Job.create(name: "refresh-exhibitors",row: 0,event_id: 280,status:'Starting...')
    script_path = "ek_scripts/external-api-imports"
    script_path = Rails.root.join("#{script_path}/#{file_name} \"280\" \"#{job.id}\" \"refresh\" \"Exhibitor\"")
    run_job_with_sidekiq_cron script_path
  end

  def plus_one_row
    raise "Cancelled" if Job.select('status').where(id:id).first.status == 'Cancelled' # query each time, because cancel will not affect job instance in scripts
    # must use self for assignment of attr_writer
    self.row = row + 1
    # at 3021 writes it fails. I think I have my answer to the strange errors I was getting.
    # There is some limit or chance of failure to writing a file this many times.
    # How could I ensure that didn't happen? Bumping from 10 to 100 works.
    # I could also make the rows_per_write a fraction of the total_rows
    # write_to_file
    write_to_file if row % rows_per_write == 0
  end

  # a little fallible, since there might be other reasons a job would be updated
  # than the original upload, but currently we don't. Update this method if we do
  # in the future.
  def duration_in_seconds
    updated_at - created_at
  end

  def rows_per_write
    # limit how many times we write to a file to avoid errors
    if total_rows
      r = total_rows / 25
      r > 10 ? r : 10
    else
      100
    end
  end

  def add_warning string
    update! warnings: (warnings || "").split("||").push( string ).join("||")
    write_to_file
  end

  def add_info string
    update! info: (info || "").split("||").push( string ).join("||")
    write_to_file
  end

  def start
    yield
    update! status:'Completed'
    write_to_file
  rescue => e
    begin
      update! status:'Failed', error_message:e.message, backtrace:e.backtrace.inspect
    rescue
      update! status:'Failed', error_message:"error message could not be saved (probably encoding issue)", backtrace:"backtrace could not be saved (probably encoding issue)"
    end
    write_to_file
    puts e.message
    puts e.backtrace
  end

  def write_to_file
    # this function exists because I wanted a way to access data
    # without making a request to the database which would already
    # be quite busy doing inserts from the import script. It may
    # not be stictly necessary
    path = Rails.root.join('public', 'event_data', self.event_id.to_s, 'job')
    unless File.directory?(path)
     FileUtils.mkdir_p(path)
     FileUtils.chown_R 'deploy', 'deploy', path 
    end
    File.open("#{path}/job.txt", 'wb', 0777) {|file|
      file.write(as_json.to_json)}
  end

  def self.try_to_create_job(params)
    !running_jobs?(params[:event_id]) ? ajax_job_create_hash(params) : ajax_job_create_fail_hash
  end

  def self.running_jobs?(event_id)
    running_jobs(event_id).length > 0
  end

  def self.running_jobs(event_id)
    # this is a little dodgy looking, but we are building it from non-user
    # hardcoded data so it's okay
    select('id').where("event_id=? AND (#{Job.running_query})", event_id)
  end

  # def running_jobs?
  #   where(Job.running_query).length > 0
  # end

  # something about this method doesn't quite work all the time. If there
  # are enough rows to process that it can't complete before it gets pinged again,
  # it will appear to get stuck in the cms
  #
  # It's probably not actually this method itself. Because the javascript stops pinging at all,
  # even though the div doesn't get updated to say it is complete
  def xlsx_report path, sheetname, linkname, data
    # -1 because first row is headers
    update!(row: 0, total_rows: data.length - 1, status:'Adding Rows to Excel Sheet')
    write_to_file

    dirname = File.dirname( path )
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    p = Axlsx::Package.new
    p.use_shared_strings = true
    wb = p.workbook

    job = self # block here won't have access to self
    SimpleXlsxTable.add_sheet( wb, sheetname, data, ( [] || false ), ( [] || false ) ) {
      job.plus_one_row
    }

    p.serialize( path )

    add_info "<a class='btn btn-success btn-sm' href='#{path.to_s.split('public')[1]}'>#{linkname}</a>"
  end
  # def xlsx_report path, sheetname, linkname, data, options={}
  #   unless options.fetch(:multipage, false) # data expected to be an array of 2d arrays if true
  #     data = [data]
  #   end

  #   # -1 because first row is headers
  #   update!(row: 0, total_rows: data.inject(-1) {|sum, i| sum + i.length}, status:'Adding Rows to Excel Sheet')
  #   write_to_file

  #   dirname = File.dirname( path )
  #   FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  #   p = Axlsx::Package.new
  #   p.use_shared_strings = true
  #   wb = p.workbook

  #   job = self # block here won't have access to self
  #   data.each_with_index do |sheet, i|
  #     SimpleXlsxTable.add_sheet( wb, sheetname+" "+i, sheet, ( [] || false ), ( [] || false ) ) {
  #       job.plus_one_row
  #     }
  #   end

  #   p.serialize( path )

  #   add_info "<a class='btn' href='#{path.to_s.split('public')[1]}'>#{linkname}</a>"
  # end

  private

  def self.run_job_with_sidekiq_cron cmd
    puts cmd.inspect.red
    system("ROO_TMP='/tmp' ruby #{cmd} 2>&1")
  end

  def self.running_query
    Job.running_statuses.map {|j| "status='#{j}'"}.join(' OR ')
  end

  # probably would have been better just to have a set of failure statuses.... this is a long list
  def self.running_statuses
    [
      'In Progress',
      'Starting...',
      'Regenerating Tags',
      'Processing Rows',
      'Processing Photos',
      'Processing Notes',
      'Fetching data from API',
      'Removing data that will be regenerated',
      'Removing missing records',
      'Cleanup',
      'Verifying no duplicate favourites.',
      'Verifying Tags',
      'Generating Delta Report',
      'Searching for new or updated records',
      'Fetching Rows From Database',
      'Adding Rows to Excel Sheet',
      'Preparing Rows',
      "Writing Event App Report By Hour",
      "Writing Event App Report By Date",
      "Writing Event App Device Summary",
      "Writing Event App Summary"
    ]
  end

  def self.ajax_job_create_hash(params)
    job = Job.create(event_id:params[:event_id], name:params[:name], status:'Starting...')
    job.write_to_file
    { status:true, message: "Successfully created job.", job_id: job.id }
  end

  def self.ajax_job_create_fail_hash
    { status:false, message: "A job is already currently running for this event." }
  end

end
