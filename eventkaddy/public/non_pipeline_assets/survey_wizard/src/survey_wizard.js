// I wonder if I am going to have trouble with the amount of disc space babel needs on hermes.
// We are always running out of space on that server... probably because of all
// the different rvm projects with their own gems we have
var $ = require("jquery");

// There is a great deal of boilerplate in this object. If ever this needed to be
// extensively modified, reducing that boilerplate might be very helpful, as
// right now many places need to be updated / added to add a column

// - [ ] get npm on hermes... or live with putting the minified file in the repo

const months = {
	January: "01",
	February: "02",
	March: "03",
	April: "04",
	May: "05",
	June: "06",
	July: "07",
	August: "08",
	September: "09",
	October: "10",
	November: "11",
	December: "12",
};
const survey_type_names = {
	1: "Global Poll",
	2: "Daily Questions",
	3: "Session Survey",
};
const question_type_names = { 1: "Multiple Choice", 2: "Long Form" };

function swapNodes(a, b) {
	var aparent = a.parentNode;
	var asibling = a.nextSibling === b ? a : a.nextSibling;
	b.parentNode.insertBefore(a, b);
	aparent.insertBefore(b, asibling);
}

function reorderElements(
	els,
	child_query,
	tree_prefix_query,
	order,
	prefix_string,
	direction
) {
	if (typeof direction === "number") {
		var to_order = order + direction;

		// this will return an array with a single element, or an empty array... we'll take advantage of that to dodge null errors
		var container_a = els.filter(function () {
			return parseInt($(this).attr("data-order")) == order;
		});
		var container_b = els.filter(function () {
			return parseInt($(this).attr("data-order")) == to_order;
		});

		function flash(el, duration) {
			el.animate({ "background-color": "#95FBA3" }, duration * 0.3);
			el.animate({ "background-color": "none" }, duration * 0.6);
		}

		container_b.each(function () {
			var $b = $(this);
			container_a.each(function () {
				var $a = $(this);
				swapNodes($a[0], $b[0]);
				var a_order = $a.attr("data-order");
				var b_order = $b.attr("data-order");
				$a.attr("data-order", b_order);
				$b.attr("data-order", a_order);

				if (child_query) {
					var container_a_child = container_a
						.children(child_query)
						.attr("data-order", b_order);
					var container_b_child = container_b
						.children(child_query)
						.attr("data-order", a_order);
				}

				var $treeprefix = $a.find(tree_prefix_query);
				var new_html = ($treeprefix.html() || "").replace(
					prefix_string + $b.attr("data-order"),
					prefix_string + $a.attr("data-order")
				);
				$treeprefix.html(new_html);
				flash($treeprefix, 2000);

				var $treeprefix = $b.find(tree_prefix_query);
				var new_html = ($treeprefix.html() || "").replace(
					prefix_string + $a.attr("data-order"),
					prefix_string + $b.attr("data-order")
				);
				$treeprefix.html(new_html);
				flash($treeprefix, 2000);
			});
		});
	} else {
		els.each(function () {
			var $con = $(this);

			if (parseInt($con.data("order")) <= order) return true;

			var new_order = parseInt($con.attr("data-order")) - 1;

			$con.attr("data-order", new_order);
			// answers and hints containers do not have an order, because they
			// contain all answers and hints, unlike questions and sections which
			// have a container per ordered question and section
			if (child_query) $con.children(child_query).attr("data-order", new_order);

			// did I forget to include this? What happened? I thought I had it working and tested?
			var $treeprefix = $con.find(tree_prefix_query);
			if ($treeprefix.html()) {
				var new_html = $treeprefix
					.html()
					.replace(prefix_string + (new_order + 1), prefix_string + new_order);
				$treeprefix.html(new_html);
			}
		});
	}
}

// global.test_reorder = function() {

//     // So... this works just fine
//     // just need the rails side to update everything as well.
//     // and to add some gui for warren
//     //
//     // I have to admit there's also some real usability issues when editing questions... a simple save button would do a lot
//     // Maybe just 'Save' 'Save and Proceed' 'Save &...'
//     //
//     // Also I need to remove the number gui thing I added, that's not really intuitive or nice
//     //
//     // Warren also says that he wants to be able to pick a question, hit "add another question" and be able to add a question beneath the one he had just selected

//     reorderElements(
//         SurveyWizard.$tree_survey_sections.children('.tree-survey_section-container'),
//         '.tree-survey_section_heading, .tree-survey_section_subheading', '.tree-survey_section_heading > .treeprefix', 2, 'Heading ',
//         1
//     )
// }

var SurveyWizard = {
	showSynced: function () {
		$(".sync_status").show().fadeOut(3000);
	},
	months: months,
	survey_type_names: survey_type_names,
	// I think these are superfluous now
	question_type_names: question_type_names,

	autoScrollEnabled: false,

	toggleAutoScroll: function () {
		this.autoScrollEnabled = this.autoScrollEnabled ? false : true;
		this.$wizard_scroll.html(
			this.autoScrollEnabled
				? "Turn Off Autoscroll to Bottom"
				: "Turn On Autoscroll to Bottom"
		);
	},

	// these reorder functions all work the same way, I should just abstract them
	reorderSurveySectionTreeElements: function (order, direction) {
		reorderElements(
			SurveyWizard.$tree_survey_sections.children(
				".tree-survey_section-container"
			),
			".tree-survey_section_heading, .tree-survey_section_subheading",
			".tree-survey_section_heading > .treeprefix",
			order,
			"Heading ",
			direction
		);
	},

	reorderQuestionTreeElements: function (order, survey_section_id, direction) {
		reorderElements(
			SurveyWizard.$tree_survey_sections
				.children(
					'.tree-survey_section-container[data-survey_section_id="' +
						survey_section_id +
						'"]'
				)
				.children(".tree-question-container"),
			".tree-question_question, .tree-question_type",
			".tree-question_question > .treeprefix",
			order,
			"Question ",
			direction
		);
	},

	reorderAnswerTreeElements: function (order, question_id, direction) {
		reorderElements(
			$(
				'.answers-container[data-question_id="' +
					question_id +
					'"] > .tree-answer_answer'
			),
			false,
			".treeprefix",
			order,
			"Answer ",
			direction
		);
	},

	reorderHintTreeElements: function (order, question_id, direction) {
		reorderElements(
			$(
				'.hints-container[data-question_id="' +
					question_id +
					'"] > .tree-hint_hint'
			),
			false,
			".treeprefix",
			order,
			"Hint ",
			direction
		);
	},

	deleteModel: function ($delete_button) {
		var model_name = $delete_button.data("model");
		var survey_section_id, question_id, answer_id, order;

		if (model_name === "survey_section") {
			survey_section_id = parseInt(
				$('.wizard-view[data-hash="#' + model_name + '"]').attr(
					"data-survey_section_id"
				)
			);
			order = this.returnSurveySectionOrderFromViewData();

			if (this.survey_sections.where({ id: survey_section_id }).length === 0) {
				$(
					'.tree-survey_section-container[data-order="' + order + '"]'
				).remove();
				return false;
			}
		} else if (model_name === "question") {
			question_id = parseInt(
				$('.wizard-view[data-hash="#' + model_name + '"]').attr(
					"data-question_id"
				)
			);
			order = this.returnQuestionOrderFromViewData();

			if (this.questions.where({ id: question_id }).length === 0) {
				$('.tree-question-container[data-order="' + order + '"]').remove();
				return false;
			}

			survey_section_id = this.questions.firstWhere({ id: question_id }).data
				.survey_section_id;
		} else if (model_name === "answer") {
			question_id = this.returnQuestionIdFromAnswerViewData();
			order = this.returnAnswerOrderFromViewData();
			answer_id = this.returnAnswerIdFromViewData();

			if (this.answers.where({ id: answer_id }).length === 0) {
				$(
					'.tree-answer_answer[data-question_id="' +
						question_id +
						'"][data-order="' +
						order +
						'"]'
				).remove();
				return false;
			}
		} else if (model_name === "hint") {
			question_id = this.returnQuestionIdFromHintViewData();
			order = this.returnHintOrderFromViewData();
			hint_id = this.returnHintIdFromViewData();

			if (this.hints.where({ id: hint_id }).length === 0) {
				$(
					'.tree-hint_hint[data-question_id="' +
						question_id +
						'"][data-order="' +
						order +
						'"]'
				).remove();
				return false;
			}
		}

		if (model_name === "survey_section") {
			$.when(
				this.survey_sections.firstWhere({ id: survey_section_id }).destroy()
			).done(function () {
				$(
					'.tree-survey_section-container[data-order="' + order + '"]'
				).remove();
				SurveyWizard.reorderSurveySectionTreeElements(order);
				WizardRouter.showRoute("#title");
			});
		} else if (model_name === "question") {
			// can this promise here possibly be doing anything....
			// I am feeding the result imediately into the when()
			$.when(this.questions.firstWhere({ id: question_id }).destroy()).done(
				function () {
					$('.tree-question-container[data-order="' + order + '"]').remove();
					SurveyWizard.reorderQuestionTreeElements(order, survey_section_id);
					WizardRouter.showRoute("#title");
				}
			);
		} else if (model_name === "answer") {
			$.when(this.answers.firstWhere({ id: answer_id }).destroy()).done(
				function () {
					$(
						'.tree-answer_answer[data-question_id="' +
							question_id +
							'"][data-order="' +
							order +
							'"]'
					).remove();
					SurveyWizard.reorderAnswerTreeElements(order, question_id);
					WizardRouter.showRoute("#title");
				}
			);
		} else if (model_name === "hint") {
			$.when(this.hints.firstWhere({ id: hint_id }).destroy()).done(
				function () {
					$(
						'.tree-hint_hint[data-question_id="' +
							question_id +
							'"][data-order="' +
							order +
							'"]'
					).remove();
					SurveyWizard.reorderHintTreeElements(order, question_id);
					WizardRouter.showRoute("#title");
				}
			);
		}
	},

	returnInputDate: function (prefix) {
		var day = $("#" + prefix + "day")
			.find(":selected")
			.text();
		day = day.length == 1 ? "0" + day : day;

		var date =
			"" +
			$("#" + prefix + "year")
				.find(":selected")
				.text() +
			"-" +
			this.months[
				$("#" + prefix + "month")
					.find(":selected")
					.text()
			] +
			"-" +
			day +
			"T" +
			$("#" + prefix + "hour")
				.find(":selected")
				.text() +
			":" +
			$("#" + prefix + "minute")
				.find(":selected")
				.text() +
			":" +
			"00Z";
		return date;
	},

	updateTimes: function () {
		console.log("updateTimes");
		this.survey.data.begins = this.returnInputDate("Begins_");
		this.survey.data.ends = this.returnInputDate("Ends_");

		this.updateSurveyTree(
			this.survey.data.begins.replace("T", " ").replace("Z", ""),
			this.$tree_begins,
			"Begins:",
			"#time"
		);
		this.updateSurveyTree(
			this.survey.data.ends.replace("T", " ").replace("Z", ""),
			this.$tree_ends,
			"Ends:",
			"#time"
		);
	},

	updateSurveyType: function () {
		var selected = this.$survey_type_select.find(":selected");
		this.survey.data.survey_type_id = selected.val();
		this.updateSurveyTree(
			selected.text(),
			this.$tree_survey_type,
			"Survey Type:",
			"#type"
		);
	},

	// return* is actually not great naming. It should be implied that all
	// functions should return something related to their name

	returnSurveySectionOrderFromViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#survey_section"]').attr("data-order")
		);
	},

	returnQuestionOrderFromViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#question"]').attr("data-order")
		);
	},

	// This might need to change so it is modifiable, or something may need to modify this value when it is updated
	returnAnswerOrderFromViewData: function () {
		return parseInt($('.wizard-view[data-hash="#answer"]').attr("data-order"));
	},

	returnHintOrderFromViewData: function () {
		return parseInt($('.wizard-view[data-hash="#hint"]').attr("data-order"));
	},

	returnSurveySectionIdFromQuestionViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#question"]').attr("data-survey_section_id")
		);
	},

	returnQuestionIdFromAnswerViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#answer"]').attr("data-question_id")
		);
	},

	returnQuestionIdFromHintViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#hint"]').attr("data-question_id")
		);
	},

	returnAnswerIdFromViewData: function () {
		return parseInt(
			$('.wizard-view[data-hash="#answer"]').attr("data-answer_id")
		);
	},

	returnHintIdFromViewData: function () {
		return parseInt($('.wizard-view[data-hash="#hint"]').attr("data-hint_id"));
	},

	returnTreeSurveySectionHeading: function (order) {
		return $('.tree-survey_section_heading[data-order="' + order + '"');
	},

	returnTreeSurveySectionSubheading: function (order) {
		return $('.tree-survey_section_subheading[data-order="' + order + '"');
	},

	returnTreeQuestionQuestion: function (order, survey_section_id) {
		return $(
			'.tree-question_question[data-order="' +
				order +
				'"][data-survey_section_id="' +
				survey_section_id +
				'"]'
		);
	},

	returnTreeAnswerAnswer: function (question_id, order) {
		return $(
			'.tree-answer_answer[data-question_id="' +
				question_id +
				'"][data-order="' +
				order +
				'"]'
		);
	},

	returnTreeHintHint: function (question_id, order) {
		return $(
			'.tree-hint_hint[data-question_id="' +
				question_id +
				'"][data-order="' +
				order +
				'"]'
		);
	},

	returnTreeQuestionType: function (order, survey_section_id) {
		return $(
			'.tree-question_type[data-order="' +
				order +
				'"][data-survey_section_id="' +
				survey_section_id +
				'"]'
		);
	},

	updateHashPath: function (ele, path) {
		ele.attr("data-hash", path);
	},

	updateAnswerCorrectness: function (checked_status) {
		var order = this.returnAnswerOrderFromViewData();
		var question_id = this.returnQuestionIdFromAnswerViewData();
		var $current_answer = this.returnTreeAnswerAnswer(question_id, order);

		this.answers
			.firstWhere({ question_id: question_id, order: order })
			.updateLocalData("correct", checked_status);
	},

	updateAnswerHandler: function (value) {
		var order = this.returnAnswerOrderFromViewData();
		var question_id = this.returnQuestionIdFromAnswerViewData();
		console.log(value);
		this.answers
			.firstWhere({ question_id: question_id, order: order })
			.updateLocalData("handler", value);
	},

	updateQuestionType: function () {
		var order = this.returnQuestionOrderFromViewData();
		var survey_section_id = this.returnSurveySectionIdFromQuestionViewData();
		var $current_question = this.returnTreeQuestionType(
			order,
			survey_section_id
		);
		var selected = this.$question_type_id.find(":selected");

		this.questions.firstWhere({
			survey_section_id: survey_section_id,
			order: order,
		}).data.question_type_id = selected.val();

		if (
			[
				"Long Form",
				"Star Rating",
				"Autocomplete Exhibitor",
				"Image Upload",
			].includes(selected.text())
		) {
			this.$proceed_to_answer_buttons.addClass("disabled");
		} else if (
			["Multiple Choice", "Multiple Select"].includes(selected.text())
		) {
			this.$proceed_to_answer_buttons.removeClass("disabled");
		}

		this.updateSurveyTree(
			selected.text(),
			$current_question,
			"Question Type: ",
			"#question"
		);
	},

	loadingIndicator: function () {
		this.$primary_instruction.html("Working...");
	},

	fillInputDetail: function (model_name, key, data) {
		$("#" + model_name + "_" + key).val(data);
	},

	fillInputDetails: function (model, keys) {
		var key;

		for (var i = 0; i < keys.length; i++) {
			key = keys[i];
			this.fillInputDetail(model.table, key, model.data[key]);
		}
	},

	addTreeSurveySections: function () {
		$.each(this.survey_sections.collection, function (i, model) {
			var order = model.data.order;

			SurveyWizard.$tree_survey_sections.append(
				'<div class="tree-survey_section-container" data-order="' +
					order +
					'" data-survey_section_id="' +
					model.data.id +
					'">' +
					'<div class="tree-survey_section_heading" data-order="' +
					order +
					'" data-id="' +
					model.data.id +
					'"></div>' +
					'<div class="tree-survey_section_subheading" data-order="' +
					order +
					'" data-id="' +
					model.data.id +
					'"></div>' +
					"</div>"
			);

			var $survey_section_heading =
				SurveyWizard.returnTreeSurveySectionHeading(order);
			var $survey_section_subheading =
				SurveyWizard.returnTreeSurveySectionSubheading(order);

			SurveyWizard.updateSurveyTree(
				model.data.heading,
				$survey_section_heading,
				"Heading " + order + ":",
				"#survey_section"
			);
			SurveyWizard.updateSurveyTree(
				model.data.subheading,
				$survey_section_subheading,
				"Sub-heading:",
				"#survey_section"
			);
		});
	},

	addTreeQuestions: function () {
		var survey_section_ids = [];

		for (var i = 0; i < this.survey_sections.collection.length; i++) {
			survey_section_ids.push(this.survey_sections.collection[i].data.id);
		}

		for (var i = 0; i < survey_section_ids.length; i++) {
			var survey_section_id = survey_section_ids[i];
			var questions = this.questions.where({
				survey_section_id: survey_section_id,
			});

			if (questions.length === 0) continue;

			var $survey_sections_container = $(
				'.tree-survey_section-container[data-survey_section_id="' +
					survey_section_id +
					'"]'
			);

			for (var q = 0; q < questions.length; q++) {
				var question = questions[q];

				var $question_container = $(
					'<div class="tree-question-container" data-id="' +
						question.data.id +
						'" data-order="' +
						question.data.order +
						'" data-survey_section_id="' +
						survey_section_id +
						'"></div>'
				).appendTo($survey_sections_container);

				// This would be much better to be abstracted... there's a lot of boiler plate for something that just takes three params
				$tree_question = $(
					'<div class="tree-question_question" data-order="' +
						question.data.order +
						'" data-survey_section_id="' +
						survey_section_id +
						'"></div>'
				).appendTo($question_container);

				this.updateSurveyTree(
					question.data.question,
					$tree_question,
					"Question " + question.data.order,
					"#question"
				);
			}
		}

		// Was this an early attempt at letting the user reorder questions?
		// $.each(this.questions.collection, function(i, model) {

		//     var order = model.data.order;

		// TODO: For a nested HTML structure like this, it would be
		// possible to have the element tag_1 contents as one arg, then
		// another function for the contents... ie // where that content can
		// itself include a nested html_element. And if you curry this
		// function, then you end up with div( tag_attrs, content ) or
		// question( content )

		// function html_element( tag, tag_attrs, content ) {
		// return `<${tag} ${tag_attrs}>${ content() }</${tag}>`
		// }
		//     SurveyWizard.$tree_questions.append(
		//         '<div class="tree-question-container" data-order="' + order + '" data-id="' + model.data.id + '">' +
		//             '<div class="tree-question_question" data-order="' + order + '" data-id="' + model.data.id + '"></div>' +
		//             '<div class="tree-question_type" data-order="' + order + '" data-id="' + model.data.id + '"></div>' +
		//         '</div>'
		//     );

		//     var $question_question = SurveyWizard.returnTreeQuestionQuestion(order);
		//     var $question_type     = SurveyWizard.returnTreeQuestionType(order);
		//     var question_type_name = SurveyWizard.question_type_names[model.data.question_type_id];

		//     SurveyWizard.updateSurveyTree(model.data.question, $question_question, 'Question ' + order + ':', '#question');

		//     SurveyWizard.updateSurveyTree(question_type_name, $question_type, 'Question Type:', '#question');

		// });
	},

	addTreeSurveyData: function () {
		this.updateSurveyTree(
			this.survey.data.title,
			this.$tree_title,
			"Title:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.description,
			this.$tree_description,
			"Description:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.post_action,
			this.$tree_post_action,
			"Post Action:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.submit_success_message,
			this.$tree_submit_success_message,
			"Submit Success Message:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.submit_failure_message,
			this.$tree_submit_failure_message,
			"Submit Failure Message:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.disallow_editing,
			this.$tree_disallow_editing,
			"Disallow Editing:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.publish_to_attendee_survey_results,
			this.$tree_publish_to_attendee_survey_results,
			"Publish To Attendee Biography:",
			"#title"
		);

		this.updateSurveyTree(
			this.survey.data.special_location,
			this.$tree_special_location,
			"Special Location:",
			"#title"
		);

		var begins, ends;

		begins =
			this.survey.data.begins === null
				? null
				: this.survey.data.begins.replace("T", " ").replace("Z", "");
		ends =
			this.survey.data.ends === null
				? null
				: this.survey.data.ends.replace("T", " ").replace("Z", "");

		this.updateSurveyTree(begins, this.$tree_begins, "Begins:", "#time");

		this.updateSurveyTree(ends, this.$tree_ends, "Ends:", "#time");

		var survey_type_name =
			this.survey_type_names[this.survey.data.survey_type_id];

		this.updateSurveyTree(
			survey_type_name,
			this.$tree_survey_type,
			"Survey Type:",
			"#type"
		);
	},

	addTreeAnswers: function () {
		var question_ids = [];

		for (var i = 0; i < this.questions.collection.length; i++) {
			question_ids.push(this.questions.collection[i].data.id);
		}

		for (var i = 0; i < question_ids.length; i++) {
			var question_id = question_ids[i];
			var answers = this.answers.where({ question_id: question_id });

			if (answers.length === 0) continue;

			var $questions_container = $(
				'.tree-question-container[data-id="' + question_id + '"]'
			);
			var $answers_container = $(
				'<div class="answers-container" data-question_id="' +
					question_id +
					'"></div>'
			).appendTo($questions_container);

			for (var q = 0; q < answers.length; q++) {
				var answer = answers[q];
				$tree_answer = $(
					'<div class="tree-answer_answer" data-order="' +
						answer.data.order +
						'" data-question_id="' +
						question_id +
						'"></div>'
				).appendTo($answers_container);

				this.updateSurveyTree(
					answer.data.answer,
					$tree_answer,
					"Answer " + answer.data.order,
					"#answer"
				);
			}
		}
	},

	addTreeHints: function () {
		var question_ids = [];

		for (var i = 0; i < this.questions.collection.length; i++) {
			question_ids.push(this.questions.collection[i].data.id);
		}

		for (var i = 0; i < question_ids.length; i++) {
			var question_id = question_ids[i];
			var hints = this.hints.where({ question_id: question_id });

			if (hints.length === 0) continue;

			var $questions_container = $(
				'.tree-question-container[data-id="' + question_id + '"]'
			);
			var $hints_container = $(
				'<div class="hints-container" data-question_id="' +
					question_id +
					'"></div>'
			).appendTo($questions_container);

			for (var q = 0; q < hints.length; q++) {
				var hint = hints[q];
				$tree_hint = $(
					'<div class="tree-hint_hint" data-order="' +
						hint.data.order +
						'" data-question_id="' +
						question_id +
						'"></div>'
				).appendTo($hints_container);

				this.updateSurveyTree(
					hint.data.hint,
					$tree_hint,
					"Hint " + hint.data.order,
					"#hint"
				);
			}
		}
	},

	fillSurveyTree: function () {
		this.addTreeSurveyData();
		this.addTreeSurveySections();
		this.addTreeQuestions();
		this.addTreeAnswers();
		this.addTreeHints();
	},

	// one of our biggest problems is redrawing the survey. Possibly when I
	// want to reorder things, I should just redraw everything... but really I
	// only want to redraw the current subtree (a list of questions, or a list
	// of answers, etc
	initForm: function () {
		if (!(SurveyWizard.survey.data.id === null)) {
			SurveyWizard.fillInputDetails(SurveyWizard.survey, [
				"title",
				"description",
				"post_action",
				"submit_success_message",
				"submit_failure_message",
				"special_location",
			]);
			if (SurveyWizard.survey.data.disallow_editing) {
				SurveyWizard.$survey_disallow_editing.prop("checked", "checked");
				SurveyWizard.$survey_disallow_editing.attr("checked", "checked");
			} else {
				SurveyWizard.$survey_disallow_editing.prop("checked", "");
				SurveyWizard.$survey_disallow_editing.attr("checked", "");
			}
			if (SurveyWizard.survey.data.publish_to_attendee_survey_results) {
				SurveyWizard.$survey_publish_to_attendee_survey_results.prop(
					"checked",
					"checked"
				);
				SurveyWizard.$survey_publish_to_attendee_survey_results.attr(
					"checked",
					"checked"
				);
			} else {
				SurveyWizard.$survey_publish_to_attendee_survey_results.prop(
					"checked",
					""
				);
				SurveyWizard.$survey_publish_to_attendee_survey_results.attr(
					"checked",
					""
				);
			}
			SurveyWizard.fillSurveyTree();
		}

		WizardRouter.showRoute("#title");
	},

	// reorder handlers also live in here.. because they have to be reattached each time
	updateSurveyTree: function (data, tree_element, prefix_string, hash) {
		if (data === null) data = "";

		if (["#question", "#answer", "#hint", "#survey_section"].includes(hash)) {
			// it might be nice to not show the arrow if it would be impossible to move up or down.
			// also a ui effect like flashing a background color would be good to show user stuff has been updated
			// var up_arrow = $('<span class="move_up">↑</span>')
			// var down_arrow = $('<span class="move_down">↓</span>')
			var arrows = $(
				'<span class="move_up">↑</span> <span class="move_down">↓</span>'
			);
			arrows.click(function (e) {
				e.stopPropagation();
				var direction = e.target.className == "move_up" ? -1 : 1;
				var order = parseInt(tree_element.attr("data-order"));
				// breaks are not implicit! if you don't add break, the other cases will run too... very annoying
				switch (hash) {
					case "#survey_section":
						var a = SurveyWizard.survey_sections.firstWhere({ order: order });
						var b = SurveyWizard.survey_sections.firstWhere({
							order: order + direction,
						});
						var reorderFn = (order, parent_id, direction) =>
							SurveyWizard.reorderSurveySectionTreeElements(order, direction); // a bit of a cheap, but just make it conform to how the other ones work
						break;
					case "#question":
						var parent_id = parseInt(
							tree_element.attr("data-survey_section_id")
						);
						var a = SurveyWizard.questions.firstWhere({
							survey_section_id: parent_id,
							order: order,
						});
						var b = SurveyWizard.questions.firstWhere({
							survey_section_id: parent_id,
							order: order + direction,
						});
						var reorderFn = SurveyWizard.reorderQuestionTreeElements;
						break;
					case "#answer":
						var parent_id = parseInt(tree_element.attr("data-question_id"));
						var a = SurveyWizard.answers.firstWhere({
							question_id: parent_id,
							order: order,
						});
						var b = SurveyWizard.answers.firstWhere({
							question_id: parent_id,
							order: order + direction,
						});
						var reorderFn = SurveyWizard.reorderAnswerTreeElements;
						break;
					case "#hint":
						var parent_id = parseInt(tree_element.attr("data-question_id"));
						var a = SurveyWizard.hints.firstWhere({
							question_id: parent_id,
							order: order,
						});
						var b = SurveyWizard.hints.firstWhere({
							question_id: parent_id,
							order: order + direction,
						});
						var reorderFn = SurveyWizard.reorderHintTreeElements;
						break;
					default:
						break;
				}

				// this check means that if you try to move a question up
				// you're currently adding, you'll have to click twice... an
				// acceptable inconvenience to keep the logic simple
				if (a && b && a.data.id && b.data.id) {
					var order_a = a.data.order;
					var order_b = b.data.order;

					a.data.order = order_b;
					b.data.order = order_a;
					a.setPending();
					b.setPending();
					reorderFn(order, parent_id, direction);
				}
			});
		} else {
			var arrows = "";
		}

		// if (data!==null) {
		tree_element.html(
			'<span class="treeprefix" data-hash="' +
				hash +
				'">' +
				prefix_string +
				"</span> " +
				data
		);
		tree_element.prepend(arrows);

		if (this.autoScrollEnabled) this.scrollDetailsToBottom();
		// }
		var order = tree_element.attr("data-order");
		var id = tree_element.attr("data-id");
		var options = {};
		var returnOptions;

		if (hash === "#question") {
			var survey_section_id = parseInt(
				tree_element.attr("data-survey_section_id")
			);
			returnOptions = function ($span) {
				return {
					order: $span.parent().attr("data-order"),
					id: id,
					survey_section_id: survey_section_id,
				};
			};
		} else if (hash === "#answer") {
			var question_id = parseInt(tree_element.attr("data-question_id"));
			returnOptions = function ($span) {
				return {
					answer_order: $span.parent().attr("data-order"),
					id: id,
					question_id: question_id,
				};
			};
		} else if (hash === "#hint") {
			var question_id = parseInt(tree_element.attr("data-question_id"));
			returnOptions = function ($span) {
				return {
					hint_order: $span.parent().attr("data-order"),
					id: id,
					question_id: question_id,
				};
			};
		} else {
			returnOptions = function ($span) {
				return { order: $span.parent().attr("data-order"), id: id };
			};
		}
		tree_element.children("span").on("click", function () {
			WizardRouter.showRoute(hash, returnOptions($(this)));
		});
	},

	titleHandler: function (value) {
		this.updateSurveyTree(value, this.$tree_title, "Title:", "#title");
		this.survey.updateLocalData("title", value);
	},

	descriptionHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_description,
			"Description:",
			"#title"
		);
		this.survey.updateLocalData("description", value);
	},

	postActionHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_post_action,
			"Post Action:",
			"#title"
		);
		this.survey.updateLocalData("post_action", value);
	},

	submitMessageSuccessHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_submit_success_message,
			"Submit Success Message:",
			"#title"
		);
		this.survey.updateLocalData("submit_success_message", value);
	},

	submitMessageFailureHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_submit_failure_message,
			"Submit Failure Message:",
			"#title"
		);
		this.survey.updateLocalData("submit_failure_message", value);
	},

	disallowEditingHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_disallow_editing,
			"Disallow Editing:",
			"#title"
		);
		this.survey.updateLocalData("disallow_editing", value);
	},

	publishToAttendeeSurveyResultsHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_publish_to_attendee_survey_results,
			"Publish To Attendee Biography:",
			"#title"
		);
		this.survey.updateLocalData("publish_to_attendee_survey_results", value);
	},

	specialLocationHandler: function (value) {
		this.updateSurveyTree(
			value,
			this.$tree_special_location,
			"Special Location:",
			"#title"
		);
		this.survey.updateLocalData("special_location", value);
	},

	headingHandler: function (value) {
		var order = this.returnSurveySectionOrderFromViewData();
		var $current_heading = this.returnTreeSurveySectionHeading(order);
		this.updateSurveyTree(
			value,
			$current_heading,
			"Heading " + order + ":",
			"#survey_section"
		);
		this.survey_sections
			.firstWhere({ order: order })
			.updateLocalData("heading", value);
	},

	subheadingHandler: function (value) {
		var order = this.returnSurveySectionOrderFromViewData();
		var $current_subheading = this.returnTreeSurveySectionSubheading(order);
		this.updateSurveyTree(
			value,
			$current_subheading,
			"Sub-heading:",
			"#survey_section"
		);
		this.survey_sections
			.firstWhere({ order: order })
			.updateLocalData("subheading", value);
	},

	questionHandler: function (value) {
		var order = this.returnQuestionOrderFromViewData();
		var survey_section_id = this.returnSurveySectionIdFromQuestionViewData();
		var $current_question = this.returnTreeQuestionQuestion(
			order,
			survey_section_id
		);
		this.updateSurveyTree(
			value,
			$current_question,
			"Question " + order + ":",
			"#question"
		);
		this.questions
			.firstWhere({ survey_section_id: survey_section_id, order: order })
			.updateLocalData("question", value);
		this.updateQuestionType();
	},

	answerHandler: function (value) {
		var order = this.returnAnswerOrderFromViewData();
		var question_id = this.returnQuestionIdFromAnswerViewData();
		var $current_answer = this.returnTreeAnswerAnswer(question_id, order);

		// Can I reuse this at all?
		this.updateSurveyTree(
			value,
			$current_answer,
			"Answer " + order + ":",
			"#answer"
		);

		this.answers
			.firstWhere({ question_id: question_id, order: order })
			.updateLocalData("answer", value);
	},

	hintHandler: function (value) {
		var order = this.returnHintOrderFromViewData();
		var question_id = this.returnQuestionIdFromHintViewData();
		var $current_hint = this.returnTreeHintHint(question_id, order);
		this.updateSurveyTree(value, $current_hint, "Hint " + order + ":", "#hint");

		this.hints
			.firstWhere({ question_id: question_id, order: order })
			.updateLocalData("hint", value);
	},

	// surveyTypeIdHandler: function(value) {

	// },

	updateTreeQuestionContainerId: function (data) {
		$(
			'.tree-question-container[data-order="' +
				data.order +
				'"][data-survey_section_id="' +
				data.survey_section_id +
				'"]'
		).attr("data-id", data.id);
	},

	updateTreeSurveySectionContainerId: function (data) {
		$('.tree-survey_section-container[data-order="' + data.order + '"]').attr(
			"data-survey_section_id",
			data.id
		);
	},

	formInvalid: function (type) {
		function isInvalid($input) {
			return $input.val() === "";
		}

		var status;
		switch (type) {
			case "survey":
				status = isInvalid(this.$survey_title);
				break;
			case "question":
				status = isInvalid(this.$question_question);
				break;
			case "answer":
				status = isInvalid(this.$answer_answer);
				break;
			case "hint":
				status = isInvalid(this.$hint_hint);
				break;
			default:
				status = false;
		}
		return status;
	},

	addWithoutSaveLinks: function () {
		$(".wizard-special-actions").append(
			"<li>" +
				'<a href="/surveys/associations/' +
				this.survey.data.id +
				'">' +
				". . . Go to Create Session Associations Page" +
				"</a>" +
				"</li>" +
				"<li>" +
				'<a href="/surveys/exhibitor_associations/' +
				this.survey.data.id +
				'">' +
				". . . Go to Create Exhibitor Associations Page" +
				"</a>" +
				"</li>" +
				"<li>" +
				'<a href="/surveys/ce_certificate_associations/' +
				this.survey.data.id +
				'">' +
				". . . Go to CE Certificate Associations Page" +
				"</a>" +
				"</li>" +
				"<li>" +
				'<a href="/surveys/questions_order/' +
				this.survey.data.id +
				'">' +
				". . . Go to Modify Question Order Page" +
				"</a>" +
				"</li>"
		);
	},

	// Do I really need this?
	dontSaveHandler: function ($dont_save_button) {
		var hash = $dont_save_button.attr("data-hash");
		var model_name = $dont_save_button.attr("data-model");
		var options = {};

		if (hash === "#survey_section") {
			options = {
				survey_section_id: $('.wizard-view[data-hash="#question"]').attr(
					"data-survey_section_id"
				),
			};
		} else if (hash === "#question") {
			var question_id = parseInt(
				$('.wizard-view[data-hash="#' + model_name + '"]').attr(
					"data-question_id"
				)
			);
			options = {
				survey_section_id: SurveyWizard.questions.firstWhere({
					id: question_id,
				}).data.survey_section_id,
			};
		} else if (hash === "#answer" || hash === "#hint") {
			options = {
				question_id: parseInt(
					$('.wizard-view[data-hash="#' + model_name + '"]').attr(
						"data-question_id"
					)
				),
			};
		}
		WizardRouter.showRoute(hash, options);
	},

	saveHandler: function ($save_button) {
		// to trigger onchange event when there is only one option in select tag
		$("#survey_type_id").trigger("change");
		var model_name = $save_button.attr("data-model");
		var model;
		var options = {};
		var order;

		if (this.formInvalid(model_name)) {
			alert("Please fill in all mandatory fields before saving.");
			return false;
		}

		if (SurveyWizard[model_name]) {
			model = SurveyWizard[model_name];
		} else {
			//it's a collection
			var model_id = $('.wizard-view[data-hash="#' + model_name + '"]').attr(
				"data-" + model_name + "_id"
			);
			if (model_id === "" && model_name === "survey_section") {
				order = this.returnSurveySectionOrderFromViewData();
				model = SurveyWizard.survey_sections.firstWhere({ order: order });
			} else if (model_id === "" && model_name === "question") {
				var survey_section_id =
					this.returnSurveySectionIdFromQuestionViewData();
				order = this.returnQuestionOrderFromViewData();
				model = SurveyWizard.questions.firstWhere({
					survey_section_id: survey_section_id,
					order: order,
				});
			} else if (model_id === "" && model_name === "answer") {
				var question_id = this.returnQuestionIdFromAnswerViewData();
				order = this.returnAnswerOrderFromViewData();
				model = this.answers.firstWhere({
					question_id: question_id,
					order: order,
				});
			} else if (model_id === "" && model_name === "hint") {
				var question_id = this.returnQuestionIdFromHintViewData();
				order = this.returnHintOrderFromViewData();
				model = this.hints.firstWhere({
					question_id: question_id,
					order: order,
				});
			} else {
				model = SurveyWizard[model_name + "s"].firstWhere({
					id: parseInt(model_id),
				});
			}
		}

		$.when(model.save()).done(function (a) {
			if (model_name === "survey_section") {
				SurveyWizard.updateTreeSurveySectionContainerId(model.data);
				options = {
					order: model.data.order,
					survey_section_id: model.data.id,
					render_new: true,
				};
			} else if (model_name === "question") {
				SurveyWizard.updateTreeQuestionContainerId(model.data);
				options = {
					order: model.data.order,
					survey_section_id: model.data.survey_section_id,
					question_id: model.data.id,
					render_new: true,
				};
			} else if (model_name === "answer") {
				var survey_section_id = SurveyWizard.questions.firstWhere({
					id: model.data.question_id,
				}).data.survey_section_id;
				options = {
					answer_order: model.data.order,
					question_id: model.data.question_id,
					render_new: true,
					survey_section_id: survey_section_id,
				};
			} else if (model_name === "hint") {
				var survey_section_id = SurveyWizard.questions.firstWhere({
					id: model.data.question_id,
				}).data.survey_section_id;
				options = {
					hint_order: model.data.order,
					question_id: model.data.question_id,
					render_new: true,
					survey_section_id: survey_section_id,
				};
			} else if (SurveyWizard.survey_id === "" && model_name === "survey") {
				SurveyWizard.survey_id = SurveyWizard.survey.data.id;
				// SurveyWizard.addWithoutSaveLinks();
			}

			WizardRouter.showRoute($save_button.attr("data-hash"), options);
		});
	},

	setHandlers: function () {
		this.$save_buttons.on("click", function () {
			if (!$(this).hasClass("disabled")) SurveyWizard.saveHandler($(this));
		});

		this.$dont_save_buttons.on("click", function () {
			SurveyWizard.dontSaveHandler($(this));
		});

		this.$delete_buttons.on("click", function () {
			SurveyWizard.deleteModel($(this));
		});

		this.$survey_title.on("input", function () {
			SurveyWizard.titleHandler($(this).val());
		});

		this.$survey_description.on("input", function () {
			SurveyWizard.descriptionHandler($(this).val());
		});

		this.$survey_post_action.on("input", function () {
			SurveyWizard.postActionHandler($(this).val());
		});

		this.$survey_submit_success_message.on("input", function () {
			SurveyWizard.submitMessageSuccessHandler($(this).val());
		});

		this.$survey_submit_failure_message.on("input", function () {
			SurveyWizard.submitMessageFailureHandler($(this).val());
		});

		this.$survey_disallow_editing.change(function () {
			SurveyWizard.disallowEditingHandler($(this).is(":checked"));
		});

		this.$survey_publish_to_attendee_survey_results.change(function () {
			SurveyWizard.publishToAttendeeSurveyResultsHandler(
				$(this).is(":checked")
			);
		});

		this.$survey_special_location.on("input", function () {
			SurveyWizard.specialLocationHandler($(this).val());
		});

		this.$survey_section_heading.on("input", function () {
			SurveyWizard.headingHandler($(this).val());
		});

		this.$survey_section_subheading.on("input", function () {
			SurveyWizard.subheadingHandler($(this).val());
		});

		this.$question_question.on("input", function () {
			SurveyWizard.questionHandler($(this).val());
		});

		this.$answer_answer.on("input", function () {
			SurveyWizard.answerHandler($(this).val());
		});

		this.$answer_handler.on("input", function () {
			SurveyWizard.updateAnswerHandler($(this).val());
		});

		this.$hint_hint.on("input", function () {
			SurveyWizard.hintHandler($(this).val());
		});

		this.$wizard_scroll.on("click", function () {
			SurveyWizard.toggleAutoScroll();
		});

		this.$time_fields.change(function () {
			SurveyWizard.updateTimes();
		});

		this.$survey_type_select.change(function () {
			SurveyWizard.updateSurveyType();
		});

		this.$question_type_id.change(function () {
			SurveyWizard.updateQuestionType();
		});

		this.$answer_correct.change(function () {
			SurveyWizard.updateAnswerCorrectness($(this).is(":checked"));
		});
	},

	scrollDetailsToBottom: function () {
		this.$tree_container[0].scrollTop = this.$tree_container[0].scrollHeight;
	},

	returnSurveyIdFromWindow: function () {
		var id = window.location.search.replace("?id=", "");
		if (id.length > 0) id = parseInt(id);
		return id;
	},

	// I don't know that I like this pattern at all. The only thing it achieves is a slight performance boost due to not requerying
	setVariables: function () {
		this.$primary_instruction = $(".primary-instruction");

		this.$tree_container = $(".survey-tree-container");
		this.$tree_title = $(".tree-title");
		this.$tree_description = $(".tree-description");
		this.$tree_post_action = $(".tree-post_action");
		this.$tree_submit_success_message = $(".tree-submit_success_message");
		this.$tree_submit_failure_message = $(".tree-submit_failure_message");
		this.$tree_disallow_editing = $(".tree-disallow_editing");
		this.$tree_publish_to_attendee_survey_results = $(
			".tree-publish_to_attendee_survey_results"
		);
		this.$tree_special_location = $(".tree-special_location");
		// this.$tree_times             = $('.tree-times');
		this.$tree_begins = $(".tree-begins");
		this.$tree_ends = $(".tree-ends");
		this.$tree_survey_type = $(".tree-survey-type");
		this.$tree_survey_sections = $(".tree-survey_sections");
		// this.$tree_questions            = $('.tree-questions');

		this.$save_buttons = $(".save_button");
		this.$dont_save_buttons = $(".dont_save_button");
		this.$delete_buttons = $(".wizard-removal");

		this.$question_save_button = $("#question_save_button");

		this.$proceed_to_answer_buttons = $(".proceed_to_answer_button");

		this.$survey_title = $("#survey_title");
		this.$survey_description = $("#survey_description");
		this.$survey_post_action = $("#survey_post_action");
		this.$survey_submit_success_message = $("#survey_submit_success_message");
		this.$survey_submit_failure_message = $("#survey_submit_failure_message");
		this.$survey_disallow_editing = $("#survey_disallow_editing");
		this.$survey_publish_to_attendee_survey_results = $(
			"#survey_publish_to_attendee_survey_results"
		);
		this.$survey_special_location = $("#survey_special_location");
		this.$time_fields = $(".time-field");
		this.$survey_type_select = $("#survey_type_id");

		this.$survey_section_heading = $("#survey_section_heading");
		this.$survey_section_subheading = $("#survey_section_subheading");

		this.$question_question = $("#question_question");
		this.$question_type_id = $("#question_type_id");

		this.$answer_answer = $("#answer_answer");
		this.$answer_handler = $("#answer_handler");
		this.$hint_hint = $("#hint_hint");

		this.$survey_section_label = $("#survey_section-label");
		this.$question_label = $("#question-label");
		this.$answer_correct = $("#answer_correct");
		this.$answer_label = $("#answer-label");
		this.$hint_label = $("#hint-label");

		this.$tree_prefixs = $(".treeprefix");

		this.$survey_view_extra_details = $(
			".survey-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$type_view_extra_details = $(
			".type-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$time_view_extra_details = $(
			".time-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$survey_section_view_extra_details = $(
			".survey_section-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$question_view_extra_details = $(
			".question-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$answer_view_extra_details = $(
			".answer-view > .wizard-form > .field > .wizard-extra-details"
		);
		this.$hint_view_extra_details = $(
			".hint-view > .wizard-form > .field > .wizard-extra-details"
		);

		this.$wizard_scroll = $("#wizard-scroll");

		this.survey_id = this.returnSurveyIdFromWindow();

		this.survey = new SurveyModel({ id: this.survey_id });

		this.survey_sections = new SurveySectionsCollection(this.survey_id);
		this.questions = new QuestionsCollection(this.survey_id);
		this.answers = new AnswersCollection(this.survey_id);
		this.hints = new HintsCollection(this.survey_id);

		// do I necessarily start with a survey_id ?
		// also techinically need to remember to save the Survey even though it's not a collection
		this.collections = [
			this.survey_sections,
			this.questions,
			this.answers,
			this.hints,
		];

		// if (this.survey_id!=='') this.addWithoutSaveLinks();
	},

	populateData: function () {
		this.loadingIndicator();
		$.when(
			this.survey.populateData(),
			this.survey_sections.populateCollection(),
			this.questions.populateCollection(),
			this.answers.populateCollection(),
			this.hints.populateCollection()
		).done(function () {
			SurveyWizard.initForm();
		});
	},

	init: function () {
		WizardRouter.init();
		this.setVariables();
		this.setHandlers();
		this.populateData();
	},
};

global.SurveyWizard = SurveyWizard;
