modulejs.define('messages/messages', function () {
  var MG = {
    getUrlVars: function () {
      var vars = [],
        hash
      var hashes = window.location.href
        .slice(window.location.href.indexOf('?') + 1)
        .split('&')
      for (var i = 0; i < hashes.length; i++) {
        hash = hashes[i].split('=')
        vars.push(hash[0])
        vars[hash[0]] = hash[1]
      }
      return vars
    },

    returnID: function (name) {
      //console.log('name ='+name);
      if (name.lastIndexOf('[') >= 0) {
        return name.substring(name.lastIndexOf('[') + 1, name.lastIndexOf(']'))
      }
      return name
    },

    returnName: function (name) {
      //console.log('name ='+name);
      if (name.lastIndexOf('[') >= 0) {
        return name.substring(0, name.lastIndexOf('['))
      }
      return name
    },

    styledName: function (name) {
      return name.substring(0, name.lastIndexOf('[') - 1)
    },

    returnNameBubble: function (name) {
      var bubble =
        '<div class="name-bubble" id="attendee' +
        MG.returnID(name) +
        '">' +
        // MG.styledName(name) +
        MG.returnName(name) +
        '</div>'

      return bubble
    },

    appendToRecipientsContainer: function (name) {
      if (
        MG.$recipients_added_container.html() === 'No recipients selected yet.'
      ) {
        MG.$recipients_added_container.html('')
      }

      var $bubble = $(MG.returnNameBubble(decodeURIComponent(name))).appendTo(
        MG.$recipients_added_container
      )

      $remove_button = $(
        '<span class="remove-recipient glyphicon glyphicon-remove"></span>'
      ).appendTo($bubble)

      $remove_button.on('click', function () {
        var ID = $(this)
          .parent()
          .attr('id')
        ID = ID.substring(8, ID.length)
        MG.removeRecipient(ID)
      })
    },

    addIDToHiddenArray: function (reg_id) {
      console.log(reg_id)
      if (MG.$recipient_form_input.val() === '') {
        MG.$recipient_form_input.val(MG.returnID(reg_id))
      } else {
        MG.$recipient_form_input.val(
          MG.$recipient_form_input.val() + ',' + MG.returnID(reg_id)
        )
      }
      //console.log("Value after adding: "+MG.$recipient_form_input.val())
    },

    alreadyAdded: function (name) {
      // var temp_name = MG.returnName(name);
      return (
        MG.$recipients_added_container.html().indexOf(MG.returnName(name)) !==
        -1
      )
    },

    addRecipient: function () {
      var name = MG.$search_input.val()
      //console.log(name);
      //|| MG.styledName(name)===''
      if (MG.alreadyAdded(name)) return

      MG.appendToRecipientsContainer(name)
      //MG.addIDToHiddenArray(name);
      MG.$search_input.val('')
    },

    removeFromRecipientsContainer: function (id) {
      //console.log(id);
      $('#attendee' + id).remove()
    },

    removeIDFromHiddenArray: function (id) {
      var arr = MG.$recipient_form_input.val().split(',')

      for (x = 0; x < arr.length; x++) {
        if (arr[x] === id) arr.splice(x, 1)
      }

      MG.$recipient_form_input.val(arr.join())
    },

    removeRecipient: function (id) {
      MG.removeIDFromHiddenArray(id)
      MG.removeFromRecipientsContainer(id)
    },

    initializeAutocomplete: function (ele, data) {
      ele.autocomplete({
        source: data,
        focus: function (event, ui) {
          event.preventDefault()
          $(this).val(ui.item.label)
        },
        select: function (event, ui) {
          event.preventDefault()
          MG.addIDToHiddenArray(ui.item.label + '[' + ui.item.value + ']')
          $(this).val(ui.item.label + '[' + ui.item.value + ']')
          MG.addRecipient()
        }
      })
    },

    setSearchInputAutocomplete: function () {
      $.getJSON(MG.attendees_array_url, function (data) {
        MG.initializeAutocomplete(MG.$search_input, data)
      })
    },

    prepopulateAttendeeOrGroup: function (name, group_id) {
      if (MG.alreadyAdded(name + '[' + group_id + ']')) {
        //console.log(name+'['+group_id+']');
        return
      }
      MG.addIDToHiddenArray(name + '[' + group_id + ']')
      MG.appendToRecipientsContainer(name + '[' + group_id + ']')
      MG.$search_input.val('')
    },
    setHandlers: function () {
      MG.setSearchInputAutocomplete()
      MG.$add_recipient_button.on('click', function () {
        MG.addRecipient()
      })
    },

    setVariables: function () {
      MG.$search_input = $('#search-input')
      MG.$recipients_added_container = $('#recipients-added-container')
      MG.$recipient_form_input = $('#recipient_attendees')
      MG.$add_recipient_button = $('#add-recipient')
      MG.attendees_array_url = '/ajax_attendees_array'
      //MG.$recipient_form_input.val('');
    },

    init: function () {
      MG.setVariables()
      MG.setHandlers()
    }
  }
  return MG
})
