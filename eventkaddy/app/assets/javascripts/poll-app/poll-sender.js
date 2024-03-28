var PollSender = (function () {
	var CT = {
		client: undefined,

		channel: undefined,

		session_id: undefined,

		publishPoll: function (data) {
			var publication = CT.client.publish(CT.channel, data);

			publication.callback(function () {
				return;
			});
			publication.errback(function () {
				return;
			});
			return false;
		},

		setupClient: function (poll_url) {
			CT.client = new Faye.Client(poll_url + "/faye");
		},

		setSessionID: function (session_id) {
			CT.session_id = session_id;
		},

		setChannel: function () {
			CT.channel = "/session_polls/" + CT.session_id;
		},

		init: function (session_id, poll_url, data) {
			CT.setupClient(poll_url);
			CT.setSessionID(session_id);
			CT.setChannel();
			CT.publishPoll(data);
			return CT;
		},
	};
	return CT;
})();
