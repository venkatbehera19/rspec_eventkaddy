class JobsController < ApplicationController

  #RAILS4 TODO: before filter changes to before_action
  before_action :authorization_check
  layout 'subevent_2013'

  def create_job
    render :json => Job.try_to_create_job(params)
  end

  def cancel_jobs
    Job.where("event_id=? AND (#{Job.running_query})", session[:event_id]).each {|j|
      j.update!(status:"Cancelled")
      j.write_to_file
    }
    render :json => {status:'Success'}
  end

  def job_status
    path = Rails.root.join('public', 'event_data', session[:event_id].to_s, 'job')
    render :json => File.read("#{path}/job.txt")
  end

  private

  def authorization_check
    authorize! :client, :all
  end

end
