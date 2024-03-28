/* Backbone Collections */

//Speakers
EK.SpeakerCollection = Backbone.Collection.extend({
 
	model: EK.Speaker,

 	url: '/speakers',
		
	comparator: function(speaker) {
     	return speaker.toJSON().speaker.id
	},

});

EK.speakerList = new EK.SpeakerCollection;