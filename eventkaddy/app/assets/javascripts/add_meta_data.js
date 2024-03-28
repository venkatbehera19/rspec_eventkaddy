$(document).ready(function(){

  let job_stats = $('#job_status_field').val();
  if (job_stats === 'in_progress'){
    fetchJobStatus();
  }
  $('#add-meta-data').on('click', function(){
    $.post("/custom_adjustments/add_meta_data_to_tags", null,
      function (data, textStatus, jqXHR) {
        if (data.alert && data.alert === 'refresh')
          location.reload();
        else if (data.job_id){
          fetchJobStatus();
        }
      }
    );
  });
});

function fetchJobStatus(){
  $.get("/custom_adjustments/meta_data_job_status", null,
    function (data, textStatus, jqXHR) {
      let jobData = data.data;
      if (jobData) {
        updateUI(jobData.status, jobData.fail_message, jobData.update_dt)
      }
    }
  );
}

function updateUI(status, msg = '', updateAt = ''){
  let jobStatsUI = $('#job_status');
  let jobMsgUI = $('#job_msg');
  if (status === 'done'){
    jobStatsUI.css({color: 'green'});
    jobStatsUI.text('Done');
    jobMsgUI.text('Last Update at ' + updateAt);
  } else if (status === 'in_progress'){
    jobStatsUI.css({color: '#2fa4e7'});
    jobStatsUI.text('In Progress..');
    jobMsgUI.text('');
    setTimeout(fetchJobStatus, 3000);
  } else if (status === 'failed'){
    jobStatsUI.css({color: '#c71c22'});
    jobStatsUI.text('In Progress..');
    jobMsgUI.text(msg);
  }
}