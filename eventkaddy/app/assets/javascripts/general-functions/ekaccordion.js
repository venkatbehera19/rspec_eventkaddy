modulejs.define('general_functions/ekaccordion', function () {
  var Acc = {
    eles: undefined,

    degrees_per_frame: 10,

    rotateArrow: function (ele, degrees) {
      ele.css({
        '-webkit-transform': 'rotate(' + degrees + 'deg)',
        '-moz-transform': 'rotate(' + degrees + 'deg)',
        '-ms-transform': 'rotate(' + degrees + 'deg)',
        transform: 'rotate(' + degrees + 'deg)'
      })
    },

    fetchAndAppendAndAnimateAccodionContainerItems: function (ele, opts) {
      var $ele = $(ele),
        name
      $ele.append('<img class="load-image" src="/ek/load.gif"/>')

      switch (this.filter) {
        case 'tag':
          name = $ele.attr('data-tag_id')
          break
        case 'date':
          name = $ele.attr('data-date')
          break
        case 'favourites':
          name = $ele.attr('data-date')
          break
        case 'my_ce':
          name = $ele.attr('data-date')
          break
        case 'speaker':
          name = $ele.attr('data-speaker_id')
          break
        case 'alphabet':
          name = $ele.attr('data-name')
          break
        case 'e_tag':
          name = $ele.attr('data-tag_id')
          break
        case 'sponsors':
          name = $ele.attr('data-tag_id')
          break
        case 'a_alphabet':
          name = $ele.attr('data-name')
          break
        case 'a_tag':
          name = $ele.attr('data-tag_id')
          break
      }

      $.get(
        '/fetch_accordion_container_items/' +
          name +
          '/' +
          Acc.filter +
          '/' +
          Acc.tag_type,
        function (html) {
          $(html).insertAfter($ele)
          console.log(Acc.className)
          $(ele)
            .siblings('.' + Acc.className + '-container-has-parent')
            .each(function () {
              $(this).css(
                'margin-left',
                parseInt($(this).css('margin-left')) + 25 + 'px'
              )
              Acc.addHandlers($(this).children('.accordion-container-item'))
            })
          $ele.children('.load-image').remove()
          Acc.animate(ele)
        }
      )
    },

    animate: function (ele) {
      var opts = this.getAnimateOpts(ele)
      // if (opts.$titles.length < 10) {
      //     opts.$titles.slideToggle();
      //     Acc.degrees_per_frame = 10; }
      // else {
      opts.$titles.toggle()
      Acc.degrees_per_frame = 15 //}

      var rotate = setInterval(function () {
        Acc.rotateArrow(opts.$arrow, opts.degrees)
        if (opts.status === 'none') {
          opts.degrees += Acc.degrees_per_frame
          if (opts.degrees > 90) clearInterval(rotate)
        } else {
          opts.degrees -= Acc.degrees_per_frame
          if (opts.degrees < 0) clearInterval(rotate)
        }
      }, 35)
    },

    getAnimateOpts: function (ele) {
      var titles = $(ele).siblings(
          '.accordion-content, .' + Acc.className + '-container-has-parent'
        ),
        status = titles.css('display')
      console.log(status)
      return {
        $titles: titles,
        status: status,
        $arrow: $('.glyphicon-triangle-right.triangle-color', ele),
        degrees: status === 'none' ? 0 : 90
      }
    },

    addHandlers: function (eles) {
      eles.on('click', function (e) {
        var opts = Acc.getAnimateOpts(this)
        if (Acc.isRemote && opts.$titles.length === 0) {
          Acc.fetchAndAppendAndAnimateAccodionContainerItems(this, opts)
        } else if (
          $(this)
            .siblings('.accordion-content')
            .attr('id') &&
          $(this)
            .siblings('.accordion-content')
            .attr('id')
            .startsWith('thread')
        ) {
          //mark the thread as read
          var threadID = $(this)
            .siblings('.accordion-content')
            .attr('id')
          $.get(
            '/exhibitor_messages/markread/' +
              threadID.substring(threadID.indexOf('_') + 1, threadID.length),
            function (data) {}
          )
          Acc.animate(this)
        } else {
          Acc.animate(this)
        }
      })
    },

    init: function (eles, isRemote, filter, type) {
      Acc.eles = eles
      Acc.isRemote = isRemote || false
      Acc.filter = filter || false
      Acc.tag_type = type || 'false'
      Acc.addHandlers(Acc.eles)
      Acc.className = 'sessions-date'
      if (Acc.filter === 'alphabet' || Acc.filter === 'e_tag') {
        Acc.className = 'exhibitor-alphabet'
      } else if (Acc.filter === 'a_alphabet' || Acc.filter === 'a_tag') {
        Acc.className = 'attendee-alphabet'
      }
    }
  }

  return Acc
})
