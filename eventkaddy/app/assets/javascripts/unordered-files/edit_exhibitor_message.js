window.onload=function(){

	$("#SubmitUpload").click(function() {
		if ($('#event_file').val()===''){
			return false
		};
		$(this).parent().parent().parent().ajaxSubmit({
		  beforeSubmit: function(a,f,o) {
		   o.dataType = 'json';
		   toggleSpinner();
		  },
		  complete: function(XMLHttpRequest, textStatus) {

		  	$.ajax({
		        type: "GET",
		        dataType: "html",
		        url: "/exhibitor_portals/ajax_data",
		        success: function(data){
		        	$('#gallery').append("<div class='float'><img src='"+data+"'></img><p style='color:green;'>New</p></div>")
		        }
   			 }); 
		  	$('#event_file').val("");
		  	toggleSpinner();
		  	$(function(event, data, status, xhr) {
	    		return $("#response").html("Saved!").show().fadeOut(2000);
	  		}).bind('ajax:error', function(xhr, status, error) {});
		  },
		 });
	});

	$(".deleter").click(function() {

		var aurl=$(this).attr("href")
		console.log(aurl);
		if (confirm('Are you sure you want to delete that?')) {
			$(this).parent().parent().remove();
			$.ajax({
			  url: aurl,
			  type: "post",
			  dataType: "json",
			  data: {"_method":"delete"}
			});
		}else{
			return false;
		}
	});


	// Show spinner while saving:
	var toggleSpinner;

	toggleSpinner = function() {
	  return $("#spinner").toggle();
	};

	toggleSpinner();


	// When the page is ready:
	$(function() {
	  return $("form[data-remote]").bind('ajax:before', toggleSpinner).bind('ajax:complete', toggleSpinner).bind('ajax:success', function(event, data, status, xhr) {
	    return $("#response").html("Saved!").show().fadeOut(2000);
	  }).bind('ajax:error', function(xhr, status, error) {});
	});

};