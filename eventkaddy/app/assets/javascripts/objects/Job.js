// CMS.Job = {

//     fetch_interval: 10000,

//     fetch_url: '/job_status',

//     post_url: '/create_job',

//     $form: undefined,

//     job_id: undefined,

//     status: undefined,

//     error_message: undefined,

//     name: undefined,

//     pretty_name: undefined,

//     event_id: undefined,

//     row: 0,

//     total_rows:undefined,

//     running_statuses: #{Job.running_statuses},

//     init: function(opts) {
//         this.event_id       = opts.event_id;
//         this.name           = opts.name;
//         this.pretty_name    = opts.pretty_name;
//         this.$form          = opts.form;
//         this.fetch_interval = opts.fetch_interval || this.fetch_interval;
//         this.status         = 'Starting...';
//         this.$job_div        = $('.current-job-status');
//         this.$job_div.children('.progress').children('.bar').css('background-color', '#149bdf');
//         this.$job_div.children('.progress').children('.bar').css('width', '0%');
//         this.$job_div.children('.errors').html('');
//         if (this.pretty_name) this.$job_div.children('.status-header').html('Status for ' + this.pretty_name);
//         this.createJob();
//         return this;
//     },

//     resume: function(opts) {
//         this.fetch_interval = opts.fetch_interval || this.fetch_interval;
//         this.job_id         = opts.job_id;
//         this.$job_div       = $('.current-job-status');
//         this.showJobStatus();
//         this.fetchJob();
//         return this;
//     },

//     submitForm: function() {
//         this.$form.children('#job_id').val(this.job_id);
//         $.ajax({
//             url: this.$form.action,
//             type: 'POST',
//             data: { file: this.$form.children('#file').val(), job_id: this.job_id },
//             context: this,
//             success: function() { this.fetchJob(); }});
//         // failure: function() { this.cancelJob() }
//     },

//     showJobStatus: function() {
//         this.$job_div.show();
//     },

//     updateJobDiv: function() {
//         var row = this.row || 0;
//         var total_rows = this.total_rows || '?';
//         this.$job_div.children('.row-progress').html(row + ' out of ' + total_rows + ' rows processed.')
//         this.$job_div.children('.status').html('Current status: ' + this.status);
//         if (!isNaN(row) && !isNaN(total_rows)) this.$job_div.children('.progress').children('.bar').css('width', '' + (row / total_rows) * 100 + '%');
//         if (this.status==='Completed') {
//             this.$job_div.children('.progress').children('.bar').css('background-color', 'green'); }
//         if (this.status==='Failed') {
//             this.$job_div.children('.progress').children('.bar').css('background-color', 'red');
//             this.$job_div.children('.errors').html('Error on row ' + this.row + ': ' + this.error_message);
//         }
//     },

//     createJobSuccess: function(data) {
//         this.updateJobDiv();
//         this.showJobStatus();
//         data.status ? (this.job_id = data.job_id, this.$form.children('#job_id').val(this.job_id), $(this.$form).ajaxSubmit(), this.fetchJob())
//                     : this.status = 'Failed', this.error_message = data.message;
//     },

//     createJobFailure: function() {
//         alert("Request to start failed.");
//     },

//     createJob: function() {
//         $.ajax({
//             url: this.post_url,
//             type: 'POST',
//             data: { event_id: this.event_id, name: this.name },
//             context: this,
//             success: this.createJobSuccess,
//             failure: this.createJobFailure});
//     },

//     jobIsRunning: function() {
//         for (var i=0;i < this.running_statuses.length;i++) {
//             if (this.status===this.running_statuses[i]) return true; }
//         return false;
//     },

//     fetchSuccess: function(data) {
//         this.status        = data.status;
//         this.error_message = data.error_message;
//         this.warnings      = data.warnings;
//         this.row           = data.row;
//         this.total_rows    = data.total_rows;
//         this.updateJobDiv();
//         var that = this;
//         if (job && this.jobIsRunning()) setTimeout(function() { that.fetchJob(); }, 3000);
//     },

//     fetchJob: function() {
//         $.ajax({
//             url: this.fetch_url,
//             data: { job_id: this.job_id },
//             context: this,
//             success: this.fetchSuccess});
//     }

// };