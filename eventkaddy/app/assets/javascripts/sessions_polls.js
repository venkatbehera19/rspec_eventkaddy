function getHorizontalBarBgColors(size){
    var colors = []
      for (let i = 0; i < size; i++){
        r = parseInt( Math.random() * 230 );
        g = parseInt( 90 + Math.random() * 166 );
        b = parseInt( 50 + Math.random() * 200 );
        colors.push( `rgba(${ r }, ${ g }, ${ b }, 1.00)` )
      }
    return colors;
  }

  function checkIfLabelBig(labels) {
    areLabelBig = false
    labels.forEach(label => {
      areLabelBig = label.length > 25 
    })
    return areLabelBig;
  }

  function chartConfig(data, max) {
    labels = $('#labels').val().split("-")
    areLabelBig = checkIfLabelBig(labels)
    title = $('#title').val()
    showingPercentage = false
    colors = getHorizontalBarBgColors(labels.length)

    if(!areLabelBig){$('.options-list').hide()}

    $('li.options').each(function(index){
      // $(this).css('border', `10px solid ${colors[index]}`);
      $(this).css('backgroundColor', colors[index]);
      $(this).css('color', 'white');
      $(this).css('font-weigth', 'bold');
    })



    config = {
      type: 'bar', 
      data: {
          labels: labels,
          datasets: [{
            label: 'To %',
            data: data,
            backgroundColor: colors,
          }]
        },
      options: {

        maintainAspectRatio: false,
        indexAxis: 'y',
        elements: {
          bar: {
            borderWidth: 2,
          }
        },
        plugins: {
          legend: {
            display: true,
            labels: {
              boxHeight: 20,
              boxWidth: 40
            },

            onClick: (e) => {
              if(!showingPercentage){
                percentageArr = []
                e.chart.data.datasets[0].data.forEach(function(no){
                  percentage = (parseInt(no)/max) * 100
                  percentageArr.push(percentage.toFixed(2))
                })
                e.chart.data.datasets[0].data = percentageArr
                e.chart.data.datasets[0].label = "To No."
                new_title = title + "(%)"
              }else{
                e.chart.data.datasets[0].data = data
                e.chart.data.datasets[0].label = "To %"
                new_title = title
              }
              e.chart.options.plugins.title.text = new_title;
              e.chart.update()
              showingPercentage = !showingPercentage
            }
          }, 
          title: {
            display: false,
            text: title,
            font: { size: 40 }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                let raw = context.raw || '';
                if (showingPercentage) {
                    raw += '%';
                }
                return raw;
              }
            }
          }
        }, 
        scales: {
          x: { grid: { display: false }},
          y: { grid: { display: false },ticks: { display: !areLabelBig } },
        }
      }
    }

    return config
  }

  function updateUsingFaye(session_poll, myChart) {
    myChart = myChart
    url = $("#url").val()
    const CLIENT = new Faye.Client(url + "/faye");
    CLIENT.subscribe('/session_polls/'+ `refresh_chart/${session_poll}`, function (payload){
        if(payload.data.success){
          config = chartConfig(payload.data.values, payload.data.max)
          $(".forChart").html("<canvas id='polls_chart'></canvas>")
          ctx = document.getElementById('polls_chart').getContext('2d');
          myChart = new Chart(
            ctx,
            config
          );
        }
    })
  }

  $(document).ready(function(){
    session_poll = $('#session').val()
    data = $('#data').val().split(" ")
    max  = parseInt($('#max').val())
    config = chartConfig(data, max)
    $(".forChart").html("<canvas id='polls_chart'></canvas>")
    ctx = document.getElementById('polls_chart').getContext('2d');
    myChart = new Chart(
      ctx,
      config
    );
    updateUsingFaye(session_poll, myChart)
  })