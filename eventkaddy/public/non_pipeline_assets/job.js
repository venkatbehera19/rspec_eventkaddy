var CMS = {},
  job

CMS.Job = {
  fetch_interval: 10000,
  fetch_url: '/job_status',
  post_url: '/create_job',
  $form: undefined,
  job_id: undefined,
  status: undefined,
  error_message: undefined,
  name: undefined,
  pretty_name: undefined,
  event_id: undefined,
  row: 0,
  total_rows: undefined,
  running_statuses: undefined, // define in erb/haml template
  file: undefined,

  init: function (opts) {
    // acquired from setupJob
    // this.event_id         = opts.event_id;
    // this.running_statuses = opts.running_statuses;
    this.name = opts.name
    this.pretty_name = opts.pretty_name
    this.$form = opts.form
    this.fetch_interval = opts.fetch_interval || this.fetch_interval
    this.status = 'Starting...'
    this.$job_div = $('.current-job-status')
    this.$job_div
      .children('.progress')
      .children('.bar')
      .css('background-color', '#149bdf')
    this.$job_div
      .children('.progress')
      .children('.bar')
      .css('width', '0%')
    this.$job_div.children('.errors').html('')
    this.$job_div.children('.warnings').html('')
    this.$job_div.children('.job-info').html('')
    if (this.pretty_name) {
      this.$job_div
        .children('.status-header')
        .html('Status for ' + this.pretty_name)
    }
    this.createJob()
    return this
  },

  resume: function (opts) {
    this.fetch_interval = opts.fetch_interval || this.fetch_interval
    this.job_id = opts.job_id
    this.$job_div = $('.current-job-status')
    this.showJobStatus()
    this.fetchJob()
    return this
  },

  submitForm: function () {
    this.$form.children('#job_id').val(this.job_id)
    //alert(this.$form.attr('action'));
    let formData = new FormData()
    formData.append('job_id', this.job_id)
    formData.append('file', this.file)
    $.ajax({
      url: this.$form.attr('action'),
      type: 'POST',
      data: formData,
      context: this,
      processData: false,
      contentType: false,
      success: function () {
        this.fetchJob()
      },
      failure: function (error) {
        console.log(error)
      }
    })
    // failure: function() { this.cancelJob() }
  },

  showJobStatus: function () {
    this.$job_div.show()
  },

  updateJobDiv: function () {
    var row = this.row || 0
    var total_rows =
      this.total_rows === 0 || this.total_rows ? this.total_rows : '?'
    this.$job_div
      .children('.row-progress')
      .html(row + ' out of ' + total_rows + ' rows processed.')
    this.$job_div.children('.status').html('Current status: ' + this.status)
    if (this.warnings) {
      this.$job_div
        .children('.warnings')
        .html('Warnings: ' + this.warnings.replace(/\|\|/g, '<br>'))
    }
    if (this.info) {
      this.$job_div
        .children('.job-info')
        .html('Info: ' + this.info.replace(/\|\|/g, '<br>'))
    }
    if (!isNaN(row) && !isNaN(total_rows)) {
      this.$job_div
        .children('.progress')
        .children('.bar')
        .css('width', '' + (row / total_rows) * 100 + '%')
    }
    if (this.status === 'Completed') {
      this.$job_div
        .children('.progress')
        .children('.bar')
        .css('background-color', 'green')
    }
    if (this.status === 'Failed') {
      this.$job_div
        .children('.progress')
        .children('.bar')
        .css('background-color', 'red')
      this.$job_div
        .children('.errors')
        .html('Error on row ' + this.row + ': ' + this.error_message)
    }
  },

  createJobSuccess: function (data) {
    this.updateJobDiv()
    this.showJobStatus()
    data.status
      ? ((this.job_id = data.job_id),
        this.$form.children('#job_id').val(this.job_id),
        this.file
          ? this.submitForm()
          : ($(this.$form).ajaxSubmit(), this.fetchJob()))
      : (this.status = 'Failed'),
      (this.error_message = data.message)
  },

  createJobFailure: function () {
    alert('Request to start failed.')
  },

  createJob: function () {
    $.ajax({
      url: this.post_url,
      type: 'POST',
      data: { event_id: this.event_id, name: this.name },
      context: this,
      success: this.createJobSuccess,
      failure: this.createJobFailure
    })
  },

  jobIsRunning: function () {
    for (var i = 0; i < this.running_statuses.length; i++) {
      if (this.status === this.running_statuses[i]) return true
    }
    return false
  },

  fetchSuccess: function (data) {
    this.status = data.status
    this.error_message = data.error_message
    this.warnings = data.warnings
    this.info = data.info
    this.row = data.row
    this.total_rows = data.total_rows
    this.updateJobDiv()
    var that = this
    if (job && this.jobIsRunning())
      setTimeout(function () {
        that.fetchJob()
      }, 3000)
  },

  fetchJob: function () {
    $.ajax({
      url: this.fetch_url,
      data: { job_id: this.job_id },
      context: this,
      success: this.fetchSuccess
    })
  },

  // feed in some variables, likely from erb template, and
  // setup the job for the page. Otherwise it would have to
  // happen from a fetch
  setupJob: function (event_id, running_statuses) {
    this.event_id = event_id
    this.running_statuses = running_statuses
  }
}

$('.job-submit').on('click', function (e) {
  e.preventDefault()
  if (e.target.className.indexOf('export') !== -1 || confirm('Are you sure?')) {
    var options = {
      name: $(this).attr('data-sname'),
      pretty_name: $(this)
        .parent()
        .siblings('.label')
        .html(),
      // event_id:    event_id,
      form: $(this).parent()
      // running_statuses: running_statuses
    }
    if (job && job.jobIsRunning()) {
      alert(
        'Please wait until the current job completed before starting a new one.'
      )
    } else {
      job = Object.create(CMS.Job).init(options) // TODO: intentionally global, but should be refactored.
    }
  } else {
    return false
  }
})

$('.cancel-job').on('click', function () {
  if (confirm('Are you sure?')) {
    $.post('/cancel_jobs', function () {
      $('.current-job-status').hide()
      job.status = 'Cancelled'
      alert('Job cancelled.')
      job = undefined // TODO: change from global
    })
  }
})
