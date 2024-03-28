var $ = require('jquery')
// $.ajaxSetup({
//   headers: { 'X-CSRF-Token': $('meta[name=csrf-token]').attr('content') } // this little snip is to grab the csrf token generated in the page by rails
// })
// this was one of my early experiments in Javascript. It basically is an even
// more simplified version of the backbone.js idea, but without events or a
// router or stuff like that. Which is why this project looks more complex than
// it should be

var WizardModel = function () {}

var WizardCollection = function () {
  this.collection = []
}

WizardModel.prototype = {
  get_url: function () {
    return '/survey_wizard/get_' + this.table + '?id=' + this.data.id
  },
  post_url: function () {
    return '/survey_wizard/save_' + this.table
  },
  delete_url: function () {
    return '/survey_wizard/delete_' + this.table + '?id=' + this.data.id
  },

  updateLocalData: function (key, value) {
    this.data[key] = value
    this.setPending()
  },

  setPending: function () {
    this.sync_pending = true
  },

  setSynced: function () {
    this.sync_pending = undefined // could be false, but maybe it's easier just to make sure it's the same value
  },

  // particularly important for surveyModel, which has no collection
  sync: function () {
    this.save(function (model, response) {
      model.setSynced()
      SurveyWizard.showSynced()
    })
  },

  populateData: function () {
    var that = this

    return $.get(this.get_url(), function (data) {
      that.data =
        data.status === false ? alert('An error occured.') : data.survey
    })
  },

  destroy: function () {
    function success (response) {
      console.log(response)
    }

    function failure () {
      alert(
        'An error occured while trying to delete and the process was aborted.'
      )
    }

    var model = this

    return $.ajax({
      headers: { 'X-CSRF-Token': $('meta[name=csrf-token]').attr('content') }, // this little snip is to grab the csrf token generated in the page by rails
      url: this.delete_url(),
      type: 'DELETE',
      success: function (response) {
        if (SurveyWizard[model.table + 's']) {
          SurveyWizard[model.table + 's'].removeModel(model)
        }
      },
      error: function () {
        failure()
      }
    })
  },

  save: function (cb, fb) {
    function failure () {
      alert('An error occured while trying to save.')
    }

    var model = this

    return $.post({
      url: this.post_url(),
      data: this.data,
      success: function (response) {
        model.updateLocalData('id', response['id'])
        console.log(response)
        cb && cb(model, response)
      },
      headers: { 'X-CSRF-Token': $('meta[name=csrf-token]').attr('content') } // this little snip is to grab the csrf token generated in the page by rails
    }).fail(function (response) {
      fb ? fb(model, response) : failure()
    })
  }
}

// this is now working.
// global.testSync = function() {
//     SurveyWizard.questions.collection[0].data.question = 'test question'
//     SurveyWizard.questions.collection[0].setPending()
//     SurveyWizard.questions.sync()
// }

WizardCollection.prototype = {
  // sadly I've got all my own names for things that I've long since
  // forgotten, as I didn't use the backbone names for things so instead of
  // 'models' I have 'collection', instead of 'attributes' I have 'data'

  // for test purposes
  showPending: function () {
    console.log(this.collection.filter(m => m.sync_pending))
  },

  sync: function () {
    this.collection
      .filter(m => m.sync_pending)
      .forEach(function (model) {
        model.save(function (model, response) {
          model.setSynced()
          SurveyWizard.showSynced()
        })
      })
  },

  firstWhere: function (values) {
    function all_equal (values, data) {
      for (var key in values) {
        if (data[key] !== values[key]) return false
      }
      return true
    }

    for (var i = 0; i < this.collection.length; i++) {
      if (all_equal(values, this.collection[i].data)) return this.collection[i]
    }
  },

  where: function (values) {
    function all_equal (values, data) {
      for (var key in values) {
        if (data[key] !== values[key]) return false
      }
      return true
    }

    var result = []
    for (var i = 0; i < this.collection.length; i++) {
      if (all_equal(values, this.collection[i].data))
        result.push(this.collection[i])
    }
    return result
  },

  removeModel: function (model) {
    var i = this.collection.indexOf(model)
    if (i > -1) this.collection.splice(i, 1)

    for (i; i < this.collection.length; i++) {
      this.collection[i].data.order--
    }
  },

  addOne: function (model) {
    this.collection.push(model)
  }
}

var SurveyModel = function (data) {
  this.data = data || {
    id: '',
    order: '',
    title: '',
    description: '',
    begins: '',
    ends: '',
    survey_type_id: ''
  }
  this.table = 'survey'
}

var SurveySectionModel = function (data) {
  this.data = data || {
    id: '',
    order: '',
    survey_id: '',
    heading: '',
    subheading: ''
  }
  this.table = 'survey_section'
}

var QuestionModel = function (data) {
  this.data = data || {
    id: '',
    order: '',
    survey_section_id: '',
    survey_id: '',
    question_type_id: '',
    question: ''
  }
  this.table = 'question'
}

var AnswerModel = function (data) {
  this.data = data || {
    id: '',
    question_id: '',
    order: '',
    answer: '',
    correct: '',
    handler: ''
  }
  this.table = 'answer'
}

var HintModel = function (data) {
  this.data = data || { id: '', question_id: '', order: '', hint: '' }
  this.table = 'hint'
}

var SurveySectionsCollection = function (survey_id) {
  this.populateCollection = function () {
    var collection = this

    return $.get(this.get_url, function (data) {
      if (!(data.status === false)) {
        $.each(data, function (i, v) {
          var survey_section = new SurveySectionModel(v.survey_section)
          collection.collection.push(survey_section)
        })
      }
    })
  }
  this.get_url = '/survey_wizard/get_survey_sections?survey_id=' + survey_id
}

var QuestionsCollection = function (survey_id) {
  this.populateCollection = function () {
    var collection = this

    return $.get(this.get_url, function (data) {
      if (!(data.status === false)) {
        $.each(data, function (i, v) {
          var question = new QuestionModel(v.question)
          collection.collection.push(question)
        })
      }
    })
  }
  this.get_url = '/survey_wizard/get_questions?survey_id=' + survey_id
}

var AnswersCollection = function (survey_id) {
  this.populateCollection = function () {
    var collection = this

    return $.get(this.get_url, function (data) {
      if (!(data.status === false)) {
        $.each(data, function (i, v) {
          var answer = new AnswerModel(v.answer)
          collection.collection.push(answer)
        })
      }
    })
  }

  this.get_url = '/survey_wizard/get_answers?survey_id=' + survey_id
}

var HintsCollection = function (survey_id) {
  this.populateCollection = function () {
    var collection = this

    return $.get(this.get_url, function (data) {
      if (!(data.status === false)) {
        $.each(data, function (i, v) {
          var hint = new HintModel(v.hint)
          collection.collection.push(hint)
        })
      }
    })
  }

  this.get_url = '/survey_wizard/get_hints?survey_id=' + survey_id
}

SurveyModel.prototype = new WizardModel()
SurveySectionModel.prototype = new WizardModel()
QuestionModel.prototype = new WizardModel()
AnswerModel.prototype = new WizardModel()
HintModel.prototype = new WizardModel()
SurveySectionsCollection.prototype = new WizardCollection()
QuestionsCollection.prototype = new WizardCollection()
AnswersCollection.prototype = new WizardCollection()
HintsCollection.prototype = new WizardCollection()

// For now to maintain how things originally worked and avoid
// unexpected breaking bugs in production, keep all these globals
global.WizardModel = WizardModel
global.WizardCollection = WizardCollection
global.SurveyModel = SurveyModel
global.SurveySectionModel = SurveySectionModel
global.QuestionModel = QuestionModel
global.AnswerModel = AnswerModel
global.HintModel = HintModel
global.SurveySectionsCollection = SurveySectionsCollection
global.QuestionsCollection = QuestionsCollection
global.AnswersCollection = AnswersCollection
global.HintsCollection = HintsCollection

module.exports = {
  WizardModel: WizardModel,
  WizardCollection: WizardCollection,
  SurveyModel: SurveyModel,
  SurveySectionModel: SurveySectionModel,
  QuestionModel: QuestionModel,
  AnswerModel: AnswerModel,
  HintModel: HintModel,
  SurveySectionsCollection: SurveySectionsCollection,
  QuestionsCollection: QuestionsCollection,
  AnswersCollection: AnswersCollection,
  HintsCollection: HintsCollection
}
