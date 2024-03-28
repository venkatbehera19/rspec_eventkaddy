$(function() {
  var devIndicator = function(subdomain) {
    if (window.location.host.split('.')[0] === subdomain) {
      $devindicator = $('<div id="devindicator" style="text-align:center;padding-top:7px;border-radius:10px;height:30px;width:300px;color:white;background-color:red;z-index:9999;opacity:0.7;">' + subdomain + '</div>');
      var center_pixel = ($(window).width() / 2 - $devindicator.width() / 2);
      $devindicator.prependTo('body');
      $devindicator.css({'position' : 'fixed',
                         'left'     : center_pixel + 'px',
                         'top'      : 0            + 'px'});
      $devindicator.on('click', function() { $(this).fadeOut(); });
    }
  };
  devIndicator("localhost:3000");
  devIndicator("localhost:3001");
  devIndicator("localhost:3002");
  devIndicator("devavmaspeakers");
  devIndicator("stage");
});