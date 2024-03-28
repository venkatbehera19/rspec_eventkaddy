window.onload=function(){

	$("#SubmitUpload").click(function() {
		if ($('#event_file').val()===''){
			return false
		};
		//$(this).parents("form").submit();
		$(this).parent().parent().parent().ajaxSubmit({
		  beforeSubmit: function(a,f,o) {
		   o.dataType = 'json';
		   toggleSpinner();
		  },
		  complete: function(XMLHttpRequest, textStatus) {

		  	$.ajax({
		        type: "GET",
		        dataType: "html",
		        url: "/messages/ajax_data",
		        success: function(data){
		        	$('#gallery').append("<div class='float'><img src='"+data+"'></img><p style='color:green;'>New</p></div>")
		        	//$('#gallery').append("<div class='float'><img src='"+data+"' width='100' height='100' onclick='window.alert(&quot;https://avmaspeakers.eventkaddy.net"+data+"&quot;)'></img><p style='color:green;'>New</p></div>")
		        }
   			 }); 
		  	//$('#gallery').append(""+data[0].path+"")
   			//$('#gallery').append(""+EK.eventFile.first.path+"");

		  	//$('label').append('<img width="300" height="300" src="XMLHttpRequest.responseText">');
		  	//$('#uploadedImages').append(""+$("#event_file").val()+"<img src='/assets/checkmark.gif' width='20' height='20'><br>");
		  	$('#event_file').val("");
		  	toggleSpinner();
		  	$(function(event, data, status, xhr) {
	    		return $("#response").html("Saved!").show().fadeOut(2000);
	  		}).bind('ajax:error', function(xhr, status, error) {});
		   // XMLHttpRequest.responseText will contain the URL of the uploaded image.
		   // Put it in an image element you create, or do with it what you will.
		   // For example, if you have an image elemtn with id "my_image", then
		   //  $('#my_image').attr('src', XMLHttpRequest.responseText);
		   // Will set that image tag to display the uploaded image.
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

	//$('#uploadForm input').change(function(){
 
//});

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