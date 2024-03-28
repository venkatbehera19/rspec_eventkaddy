var $ = require('jquery')

function syncSurvey () {
  if (SurveyWizard.survey_id !== '') {
    SurveyWizard.survey.sync()
    SurveyWizard.collections.forEach(c => c.sync())
    // we would kind of like this to only happen once and only if it succeeded...
    // SurveyWizard.showSynced();
  }
}

var WizardDebug = true

var WizardRouter = {
  primary_instructions: {
    '#title': 'Name your survey.',
    '#time': 'Select times survey will be available.',
    '#type': 'Select a type.',
    '#survey_section': 'Add a survey section.',
    '#question': 'Add a question.',
    '#answer': 'Add an answer.',
    '#hint': 'Add a hint.'
  },

  setSelectedOption: function ($select_ele, value) {
    $select_ele.children().attr('selected', false)
    $select_ele
      .children('option[value="' + value + '"]')
      .attr('selected', 'selected')
  },

  setDataValues: function ($ele, values) {
    for (var key in values) {
      $ele.attr('data-' + key, values[key])
    }
  },

  renderSurveySectionLabel: function (order) {
    SurveyWizard.$survey_section_label.html(
      'Survey Section Heading ' + order + ' (will be bold)'
    )
  },

  renderQuestionLabel: function (order) {
    SurveyWizard.$question_label.html('Question ' + order)
  },

  renderAnswerLabel: function (order) {
    SurveyWizard.$answer_label.html('Answer ' + order)
  },

  renderHintLabel: function (order) {
    SurveyWizard.$hint_label.html('Hint ' + order)
  },

  appendNewTreeSurveySection: function (order) {
    if (
      $('.tree-survey_section_heading[data-order="' + order + '"]').length === 0
    ) {
      SurveyWizard.$tree_survey_sections.append(
        '<div class="tree-survey_section-container" data-order="' +
          order +
          '" data-survey_section_id="">' +
          '<div class="tree-survey_section_heading" data-order="' +
          order +
          '"></div>' +
          '<div class="tree-survey_section_subheading" data-order="' +
          order +
          '"></div>' +
          '</div>'
      )
    }
  },

  renderExtraDetails: function (route, details) {
    switch (route) {
      case 'survey':
        SurveyWizard.$survey_view_extra_details.html(details)
        break

      case 'type':
        SurveyWizard.$type_view_extra_details.html(details)
        break

      case 'time':
        SurveyWizard.$time_view_extra_details.html(details)
        break

      case 'survey_section':
        SurveyWizard.$survey_section_view_extra_details.html(details)
        break

      case 'question':
        SurveyWizard.$question_view_extra_details.html(details)
        break

      case 'answer':
        SurveyWizard.$answer_view_extra_details.html(details)
        break

      case 'hint':
        SurveyWizard.$hint_view_extra_details.html(details)
        break
    }
  },

  renderNewSurveySection: function () {
    var survey_sections = SurveyWizard.survey_sections.where({ id: '' })
    var order, survey_section

    if (survey_sections.length === 0) {
      order = SurveyWizard.survey_sections.collection.length + 1
      survey_section = new SurveySectionModel({
        id: '',
        survey_id: SurveyWizard.survey.data.id,
        order: order
      })
      SurveyWizard.survey_sections.addOne(survey_section)
    } else {
      order = SurveyWizard.survey_sections.collection.length
      survey_section = SurveyWizard.survey_sections.firstWhere({ order: order })
    }

    SurveyWizard.$survey_section_heading.val('')
    SurveyWizard.$survey_section_subheading.val('')
    this.setDataValues($('.wizard-view[data-hash="#survey_section"]'), {
      order: order,
      survey_section_id: ''
    })
    this.appendNewTreeSurveySection(order)
    this.renderSurveySectionLabel(order)
  },

  renderExistingSurveySection: function (order) {
    var survey_section = SurveyWizard.survey_sections.firstWhere({
      order: parseInt(order)
    })

    this.setDataValues($('.wizard-view[data-hash="#survey_section"]'), {
      order: order,
      survey_section_id: survey_section.data.id
    })
    SurveyWizard.fillInputDetails(survey_section, ['heading', 'subheading'])
    this.renderSurveySectionLabel(order)
  },

  renderSurveySection: function (options) {
    if (options.order !== undefined && options.render_new === undefined) {
      this.renderExistingSurveySection(options.order)
    } else {
      this.renderNewSurveySection()
    }
  },

  renderExistingQuestion: function (survey_section_id, order) {
    var question = SurveyWizard.questions.firstWhere({
      survey_section_id: parseInt(survey_section_id),
      order: parseInt(order)
    })

    this.setDataValues($('.wizard-view[data-hash="#question"]'), {
      order: order,
      survey_section_id: question.data.survey_section_id,
      question_id: question.data.id
    })
    this.setSelectedOption(
      SurveyWizard.$question_type_id,
      question.data.question_type_id
    )
    SurveyWizard.fillInputDetails(question, ['question'])
    this.renderQuestionLabel(order)
  },

  appendNewTreeQuestion: function (survey_section_id, order) {
    function noQuestionContainersInSection (survey_section_id) {
      return (
        $(
          '.tree-question-container[data-survey_section_id="' +
            survey_section_id +
            '"]'
        ).length === 0
      )
    }

    function noQuestionContainerWithOrderInSection (survey_section_id, order) {
      return (
        $(
          '.tree-question_question[data-survey_section_id="' +
            survey_section_id +
            '"][data-order="' +
            order +
            '"]'
        ).length === 0
      )
    }

    var question_container_content =
      '<div class="tree-question_question" data-survey_section_id="' +
      survey_section_id +
      '" data-order="' +
      order +
      '"></div><div class="tree-question_type" data-order="' +
      order +
      '"></div>'

    if (
      noQuestionContainersInSection(survey_section_id) ||
      noQuestionContainerWithOrderInSection(survey_section_id, order)
    ) {
      $(
        '.tree-survey_section-container[data-survey_section_id="' +
          survey_section_id +
          '"]'
      ).append(
        '<div class="tree-question-container" data-order="' +
          order +
          '" data-survey_section_id="' +
          survey_section_id +
          '">' +
          question_container_content +
          '</div>'
      )
    }
    // else if ( noQuestionContainerWithOrderInSection(survey_section_id, order) ) {
    // $('.tree-question-container[data-survey_section_id="' + survey_section_id + '"]').append(question_container_content);
    // }
  },

  renderNewQuestion: function (options) {
    var questions = SurveyWizard.questions.where({
      survey_section_id: options.survey_section_id,
      id: ''
    })
    var order, question

    if (questions.length === 0) {
      order =
        SurveyWizard.questions.where({
          survey_section_id: options.survey_section_id
        }).length + 1
      question = new QuestionModel({
        id: '',
        question: '',
        survey_id: SurveyWizard.survey.data.id,
        survey_section_id: options.survey_section_id,
        question_type_id: 1,
        order: order
      })
      SurveyWizard.questions.addOne(question)
    } else {
      order = SurveyWizard.questions.where({
        survey_section_id: options.survey_section_id
      }).length
      question = SurveyWizard.questions.firstWhere({
        survey_section_id: options.survey_section_id,
        order: order
      })
    }

    SurveyWizard.$question_question.val('')
    this.setDataValues($('.wizard-view[data-hash="#question"]'), {
      order: order,
      survey_section_id: options.survey_section_id,
      question_id: ''
    })
    this.appendNewTreeQuestion(options.survey_section_id, order)
    this.renderQuestionLabel(order)
  },

  renderQuestion: function (options) {
    if (options.order !== undefined && options.render_new === undefined) {
      this.renderExistingQuestion(options.survey_section_id, options.order)
    } else {
      this.renderNewQuestion(options)
    }

    var p1 =
      'Section ' +
      SurveyWizard.survey_sections.firstWhere({ id: options.survey_section_id })
        .data.order +
      ', '
    var p2 = SurveyWizard.survey_sections.firstWhere({
      id: options.survey_section_id
    }).data.heading

    var details =
      '<span style="font-weight:bold;font-style:italic;">' + p1 + '</span>' + p2

    this.renderExtraDetails('question', details)
  },

  appendNewTreeAnswer: function (question_id, order) {
    function noAnswerContainerFound (question_id) {
      return (
        $('.answers-container[data-question_id="' + question_id + '"]')
          .length === 0
      )
    }

    function noAnswerContainerFoundWithOrder (question_id, order) {
      return (
        $(
          '.tree-answer_answer[data-question_id="' +
            question_id +
            '"][data-order="' +
            order +
            '"]'
        ).length === 0
      )
    }

    var answer_container_content =
      '<div class="tree-answer_answer" data-question_id="' +
      question_id +
      '" data-order="' +
      order +
      '"></div>'

    if (noAnswerContainerFound(question_id)) {
      $('.tree-question-container[data-id="' + question_id + '"]').append(
        '<div class="answers-container" data-question_id="' +
          question_id +
          '">' +
          answer_container_content +
          '</div>'
      )
    } else if (noAnswerContainerFoundWithOrder(question_id, order)) {
      $('.answers-container[data-question_id="' + question_id + '"]').append(
        answer_container_content
      )
    }
  },

  renderExistingAnswer: function (options) {
    var order = options.answer_order

    var answer = SurveyWizard.answers.firstWhere({
      question_id: options.question_id,
      order: parseInt(order)
    })

    this.setDataValues($('.wizard-view[data-hash="#answer"]'), {
      order: order,
      question_id: answer.data.question_id,
      answer_id: answer.data.id
    })
    console.log(answer);
    SurveyWizard.$answer_handler.val(answer.data.handler);
    SurveyWizard.fillInputDetails(answer, ['answer'])
    this.renderAnswerLabel(order)

    if (answer.data.correct === true) {
      SurveyWizard.$answer_correct.prop('checked', 'checked')
      SurveyWizard.$answer_correct.attr('checked', 'checked')
    } else {
      SurveyWizard.$answer_correct.prop('checked', '')
      SurveyWizard.$answer_correct.attr('checked', '')
    }
  },

  renderNewAnswer: function (options) {
    var answers = SurveyWizard.answers.where({
      question_id: options.question_id,
      id: ''
    })
    var order, answer

    if (answers.length === 0) {
      order =
        SurveyWizard.answers.where({ question_id: options.question_id })
          .length + 1
      answer = new AnswerModel({
        id: '',
        question_id: options.question_id,
        correct: false,
        order: order,
        answer: '',
        survey_id: SurveyWizard.survey_id
      })
      SurveyWizard.answers.addOne(answer)
    } else {
      order = SurveyWizard.answers.where({ question_id: options.question_id })
        .length
      answer = SurveyWizard.answers.where({
        question_id: options.question_id,
        order: order
      })
    }

    SurveyWizard.$answer_answer.val('')
    SurveyWizard.$answer_handler.val('')
    this.setDataValues($('.wizard-view[data-hash="#answer"]'), {
      order: order,
      question_id: options.question_id,
      answer_id: ''
    })
    this.appendNewTreeAnswer(options.question_id, order)
    this.renderAnswerLabel(order)
  },

  renderAnswer: function (options) {
    if (
      options.answer_order !== undefined &&
      options.render_new === undefined
    ) {
      this.renderExistingAnswer(options)
    } else {
      this.renderNewAnswer(options)
    }
    this.renderExtraDetails(
      'answer',
      'For question: ' +
        SurveyWizard.questions.firstWhere({ id: options.question_id }).data
          .question
    )

    var survey_section_id = SurveyWizard.questions.firstWhere({
      id: options.question_id
    }).data.survey_section_id
    var p1 =
      'Section ' +
      SurveyWizard.survey_sections.firstWhere({ id: survey_section_id }).data
        .order +
      ', '
    var p2 =
      'Question ' +
      SurveyWizard.questions.firstWhere({ id: options.question_id }).data
        .order +
      ': '
    var p3 = SurveyWizard.questions.firstWhere({ id: options.question_id }).data
      .question

    var details =
      '<span style="font-weight:bold;font-style:italic;">' +
      p1 +
      p2 +
      '</span>' +
      p3

    this.renderExtraDetails('answer', details)
  },

  appendNewTreeHint: function (question_id, order) {
    if (
      $('.hints-container[data-question_id="' + question_id + '"]').length === 0
    ) {
      $('.tree-question-container[data-id="' + question_id + '"]').append(
        '<div class="hints-container" data-question_id="' +
          question_id +
          '">' +
          '<div class="tree-hint_hint" data-question_id="' +
          question_id +
          '" data-order="' +
          order +
          '"></div>' +
          '</div>'
      )
    } else if (
      $(
        '.tree-hint_hint[data-question_id="' +
          question_id +
          '"][data-order="' +
          order +
          '"]'
      ).length === 0
    ) {
      $('.hints-container[data-question_id="' + question_id + '"]').append(
        '<div class="tree-hint_hint" data-question_id="' +
          question_id +
          '" data-order="' +
          order +
          '"></div>'
      )
    }
  },

  renderExistingHint: function (options) {
    var order = options.hint_order
    var hint = SurveyWizard.hints.firstWhere({
      question_id: options.question_id,
      order: parseInt(order)
    })

    this.setDataValues($('.wizard-view[data-hash="#hint"]'), {
      order: order,
      question_id: hint.data.question_id,
      hint_id: hint.data.id
    })
    SurveyWizard.fillInputDetails(hint, ['hint'])
    this.renderHintLabel(order)
  },

  renderNewHint: function (options) {
    var hints = SurveyWizard.hints.where({
      question_id: options.question_id,
      id: ''
    })
    var order, hint

    if (hints.length === 0) {
      order =
        SurveyWizard.hints.where({ question_id: options.question_id }).length +
        1
      hint = new HintModel({
        id: '',
        question_id: options.question_id,
        order: order,
        hint: '',
        survey_id: SurveyWizard.survey_id
      })
      SurveyWizard.hints.addOne(hint)
    } else {
      order = SurveyWizard.hints.where({ question_id: options.question_id })
        .length
      hint = SurveyWizard.hints.where({
        question_id: options.question_id,
        order: order
      })
    }

    SurveyWizard.$hint_hint.val('')
    this.setDataValues($('.wizard-view[data-hash="#hint"]'), {
      order: order,
      question_id: options.question_id,
      hint_id: ''
    })
    this.appendNewTreeHint(options.question_id, order)
    this.renderHintLabel(order)
  },

  renderHint: function (options) {
    if (options.hint_order !== undefined && options.render_new === undefined) {
      this.renderExistingHint(options)
    } else {
      this.renderNewHint(options)
    }

    var survey_section_id = SurveyWizard.questions.firstWhere({
      id: options.question_id
    }).data.survey_section_id
    var p1 =
      'Section ' +
      SurveyWizard.survey_sections.firstWhere({ id: survey_section_id }).data
        .order +
      ', '
    var p2 =
      'Question ' +
      SurveyWizard.questions.firstWhere({ id: options.question_id }).data
        .order +
      ': '
    var p3 = SurveyWizard.questions.firstWhere({ id: options.question_id }).data
      .question

    var details =
      '<span style="font-weight:bold;font-style:italic;">' +
      p1 +
      p2 +
      '</span>' +
      p3

    this.renderExtraDetails('hint', details)
  },

  renderType: function () {
    if (SurveyWizard.survey.data.survey_type_id === null) {
      SurveyWizard.survey.data.survey_type_id = 1
    }

    this.setSelectedOption(
      SurveyWizard.$survey_type_select,
      SurveyWizard.survey.data.survey_type_id
    )

    var survey_type_name =
      SurveyWizard.survey_type_names[SurveyWizard.survey.data.survey_type_id]

    SurveyWizard.updateSurveyTree(
      survey_type_name,
      SurveyWizard.$tree_survey_type,
      'Survey Type:',
      '#type'
    )
  },

  // add autosave here...
  showRoute: function (route, options) {
    // this did not work. Nothing was saved... ah, because I haven't set sync_pending when changing routes
    syncSurvey()

    if (route === '#index') window.location.href = 'surveys'
    if (route === '#sessionassoc')
      window.location.href =
        'surveys/associations/' + SurveyWizard.survey.data.id
    if (route === '#exhibitorassoc')
      window.location.href =
        'surveys/exhibitor_associations/' + SurveyWizard.survey.data.id
    if (route === '#certificateassoc')
      window.location.href =
        'surveys/ce_certificate_associations/' + SurveyWizard.survey.data.id
    if (route === '#questionorder')
      window.location.href =
        'surveys/questions_order/' + options.survey_section_id

    var options = options || {}

    this.$views.hide()

    SurveyWizard.$primary_instruction.html(this.primary_instructions[route])

    $('.wizard-view[data-hash="' + route + '"]').show()

    if (route === '#time') SurveyWizard.updateTimes()

    if (route === '#type') this.renderType()

    if (route === '#survey_section') this.renderSurveySection(options)

    if (route === '#question') this.renderQuestion(options)

    if (route === '#answer') this.renderAnswer(options)

    if (route === '#hint') this.renderHint(options)
  },

  init: function () {
    this.$views = $('.wizard-view')
  }
}

// keeping globals to avoid creating unexpected bugs in production
global.WizardRouter = WizardRouter
global.WizardDebug = WizardDebug

module.exports = {
  WizardRouter: WizardRouter,
  WizardDebug: WizardDebug
}
