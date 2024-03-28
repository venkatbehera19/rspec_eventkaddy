var ChatSender = (function () {
  var CT = {
    client: undefined,

    channel: '/chat/',

    username: undefined,

    company: undefined,

    membership: undefined,

    chat_input: undefined,

    unsubscribe_button: undefined,

    chat_log: undefined,

    session_id: undefined,

    enter_code: 13,

    submitMessage: function (message, type = 'message') {
      var publication = CT.client.publish(CT.channel, {
        username: CT.username,
        company: CT.company,
        membership: CT.membership,
        message: message,
        session_id: CT.session_id,
        type: type,
        created_at: new Date()
      })

      publication.callback(function () {
        return
      })
      publication.errback(function () {
        return
      })
      return false
    },

    scrollToBottom: function () {
      CT.chat_log.scrollTop(CT.chat_log[0].scrollHeight)
    },

    subscribe: function () {
      try {
        client.unsubscribe(CT.channel)
      } catch (err) {}

      CT.client.subscribe(CT.channel, function (payload) {
        console.log(payload)
        if (payload.type === 'message') {
          let audio = document.getElementById('notificationAudio')
          if (audio) audio.play()
          if (payload.membership) {
            CT.chat_log.append(
              "<span class='chatname'>" +
                payload.username +
                ', ' +
                payload.company +
                "<span class='mark-premium'>*</span>" +
                ": </span><span class='chat-message'>" +
                payload.message +
                '</span><br>'
            )
          } else {
            CT.chat_log.append(
              "<span class='chatname'>" +
                payload.username +
                ', ' +
                payload.company +
                ": </span><span class='chat-message'>" +
                payload.message +
                '</span><br>'
            )
          }
        } else if (payload.type === 'subscribe') {
          CT.chat_log.append(
            "<div class='subscribed'>" + payload.username + ' joined</div>'
          )
        }
        return CT.scrollToBottom()
      })
    },

    unsubscribeAll: function () {
      CT.submitMessage('unsubscribed', 'unsubscribe')
    },

    setupClient: function (chat_url) {
      CT.client = new Faye.Client(chat_url + '/faye')
      CT.subscribe()
    },

    setHandlers: function () {
      CT.chat_input.keyup(function (e) {
        if (e.keyCode === CT.enter_code && CT.chat_input.val() !== '') {
          CT.submitMessage(CT.chat_input.val())
          CT.chat_input.val('')
        }
      })
      CT.unsubscribe_button.click(function (e) {
        CT.unsubscribeAll()
      })
    },

    setSessionID: function (exhibitor_id) {
      if (window.location.pathname.toString().includes('moderator_portals')) {
        console.log(window.location.pathname)
        CT.session_id = window.location.pathname.replace(
          '/moderator_portals/chat/',
          ''
        )
      } else {
        CT.session_id = exhibitor_id
      }
    },

    setChatInput: function () {
      CT.chat_input = $('#chat-input')
      CT.unsubscribe_button = $('#unsubscribeAll-button')
    },

    setChatLog: function () {
      CT.chat_log = $('.chat-log')
    },

    setUsername: function (exhibitor) {
      if (exhibitor) {
        CT.username = exhibitor.contact_name
        CT.company = exhibitor.company_name
      }
    },

    setChannel: function () {
      CT.channel = CT.channel + CT.session_id
    },

    init: function (exhibitor, chat_url) {
      CT.setChatInput()
      CT.setSessionID(exhibitor.id)
      CT.setChannel()
      CT.setUsername(exhibitor)
      CT.setChatLog()
      CT.setHandlers()
      CT.setupClient(chat_url)
      console.log(CT)
      return CT
    }
  }
  return CT
})()
