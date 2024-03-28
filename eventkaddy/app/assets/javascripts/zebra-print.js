var selected_device;
var devices = [];

function setup(){
	BrowserPrint.getLocalDevices(function(device_list){
		var html_select = document.getElementById("selected_device");
		for(var i = 0; i < device_list.length; i++)
		{
			//Add device to list of devices and to html select element
			var device = device_list[i];
			devices.push(device);
			var option = document.createElement("option");
			option.text = device.name;
			option.value = device.uid;
			html_select.add(option);
		}
		
	}, function(){alert("Error getting local devices")},"printer");
}

function writeToSelectedPrinter(dataToWrite)
{
	selected_device.send(dataToWrite, undefined, errorCallback);
}
var readCallback = function(readData) {
	if(readData === undefined || readData === null || readData === "")
	{
		alert("No Response from Device");
	}
	else
	{
		alert(readData);
	}
}
var errorCallback = function(errorMessage){
	alert("Error: " + errorMessage);	
}
function readFromSelectedPrinter()
{
	selected_device.read(readCallback, errorCallback);
}
function getDeviceCallback(deviceList)
{
	alert("Devices: \n" + JSON.stringify(deviceList, null, 4))
}

function onDeviceSelected(selected)
{
	for(var i = 0; i < devices.length; ++i){
		if(selected.value == devices[i].uid)
		{
			selected_device = devices[i];
			return;
		}
	}
}

$(document).ready(function(){
	setup();
	$('.print-to-printer').click(function(){
		if(selected_device){
			zplCode = $('.zpl-code').text()
			if(zplCode.trim() !== ''){
				writeToSelectedPrinter(zplCode)
			}else{
				alert('Nothing To Print')
			}
		}else{
			alert('Choose A Device')
		}
	})

	$('#selected_device').change(function(){
		if(this.value !== 'none'){
			onDeviceSelected(this)
		}
	})
})