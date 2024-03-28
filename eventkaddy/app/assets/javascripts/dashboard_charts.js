
let doughnutChartColors = ['#004c6d', '#346888', '#5886a5', '#7aa6c2', '#9dc6e0', '#c1e7ff']


$(document).ready(function(){
  if (typeof Chart == 'function'){
    function drawDoughnutChat(elementId, title, labels, data){
      new Chart(
        elementId, {
          type: "doughnut",
          data:{
            labels: labels,
            datasets: [{
              backgroundColor: doughnutChartColors.slice(labels.length),
              data: data
            }]
          }, options: {
            radius: 60,
            plugins: {
              legend: {
                display: true,
                position: 'right',
                maxWidth: 120,
                labels: {
                  boxWidth: 35
                }
              }, title: {
                display: true,
                text: title
              }
            }
          }
        }
      )
    }
    
    function getBarBgColors(size){
      let r, g, b, colors = [];
      for (let i = 0; i < size; i++){
        r = parseInt( Math.random() * 230 );
        g = parseInt( 90 + Math.random() * 166 );
        b = parseInt( 50 + Math.random() * 200 );
        colors.push( `rgba(${ r }, ${ g }, ${ b }, 0.43)` )
      }
      return colors;
    }
    
    function drawBarChart(elementID, title, labels, counts, indexAxis = 'y'){
      
      new Chart(elementID, {
        type: 'bar', 
        data: {
          labels: labels,
          datasets: [{
            data: counts,
            backgroundColor: getBarBgColors(labels.length),
          }]
        }, options: {
          indexAxis: indexAxis,
          plugins: {
            legend: {
              display: false,
            }, title: {
              display: true,
              text: title
            }
          }, scales: {
            x: { grid: { display: false } },
            y: { grid: { display: false } }
          }
        }
      })
    }

    var totalLogins = parseInt($('#total_logins').val());
    var uniqueLogins = parseInt($('#unique_logins').val());
    var nonUniqueLogins = totalLogins - uniqueLogins;

    drawDoughnutChat('overall_login_canvas', `Total logins: ${totalLogins}`,
      [`Unique`, `Non-unique`], [uniqueLogins, nonUniqueLogins]);

    var deviceLabels = [];
    var deviceCounts = [];

    $('#device_data input[type="hidden"]').each(function(){
      deviceLabels.push($(this).attr('id'));
      deviceCounts.push(parseInt($(this).val()));
    });

    drawDoughnutChat('pc_vs_web_login', `Total logins: ${totalLogins}`,
      deviceLabels, deviceCounts);

    var duckTotalLogins = $('#duck_total_logins'), duckUniqueLogins = $('#duck_unique_logins');

    if (duckTotalLogins.val() && parseInt(duckTotalLogins.val()) > 0){
      drawDoughnutChat('duck_logins', `Total Video Portal Logins: ${duckTotalLogins.val()}`,
      ['Unique', 'Non-Unique'], [parseInt(duckUniqueLogins.val()) ,parseInt(duckTotalLogins.val()) - parseInt(duckUniqueLogins.val())])
    }

    var uniqueDeviceLabels = [], uniqueDeviceCounts = [];

    $('#unique_device_data input[type="hidden"]').each(function(){
      uniqueDeviceLabels.push($(this).attr('id'));
      uniqueDeviceCounts.push(parseInt($(this).val()));
    });

    drawDoughnutChat('unique_pc_vs_web_login', `Unique logins: ${uniqueLogins}`,
      uniqueDeviceLabels, uniqueDeviceCounts);

    var groupedSurveyCountsData = JSON.parse( $('#survey_counts').val() );
    let chartsContainer = $('#bar_graph_container');
    for(let groupedSurveys of groupedSurveyCountsData){
      if (groupedSurveys.surveys && groupedSurveys.surveys.length > 0){
        chartsContainer.append(
          `<div class="col-md-6"> <canvas id="${groupedSurveys.type}" style="width: 100%;"></canvas> </div>`
        );
        var labs = [], countData = [];
        for (let survey of groupedSurveys.surveys) {
          labs.push(survey.title);
          countData.push(parseInt(survey.survey_responses_count));
        }
        drawBarChart(groupedSurveys.type, groupedSurveys.type + ' Response',
          labs, countData, 'x');
      }
    }
  }

});