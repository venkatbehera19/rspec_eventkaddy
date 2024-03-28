$(".lazyload").lazyload();

var App = (function () {
	let _state = 0;
	let clickedDiv = null;
	let leftImageWrappers = $(".left-image-wrappers");
	let leftDiv = $("#left-parent-div");
	let rightDiv = $("#right-parent-div");
	let closeButton = $("#close-toggle-button");
	let attendeeNavDiv = $("#attendee-nav-div");
	let imageCards = $(".left-image-cards");
	let previewImage = $("#previewImage");
	let previewSurveyTitle = $("#preview-survey-title");
	let previewSurveyQuestion = $("#preview-survey-question");
	let previewSurveyTime = $("#preview-survey-time");
	let previewSurveyBy = $("#preview-survey-by");
	let previewSurveyButtonsDiv = $("#preview-survey-buttons");
	let previewVerifyButton = $("#preview-verify-button");
	let previewRejectButton = $("#preview-reject-button");
	let previewundoButtons = $(".preview-undo-button");
	let previewVerifiedDiv = $("#preview-verified-div");
	let previewRejectedDiv = $("#preview-rejected-div");
	let currentSelectedIndex = null;
	let totalLength = imageCards.length;

	const _setState = function () {
		_state = _state == 0 ? 1 : 0;
	};

	const _toggle = function (clickedImage) {
		_setState();
		declare_all_variables();
		if (_state == 1) {
			clickedDiv = $(clickedImage);
			currentSelectedIndex = imageCards.index(clickedDiv);
			_showPreview();
			_loadClickedImage();
			_toggleEventListeners();
		} else {
			_hidePreview();
			_toggleEventListeners();
		}
	};

	const declare_all_variables = function () {
		leftImageWrappers = $(".left-image-wrappers");
		leftDiv = $("#left-parent-div");
		rightDiv = $("#right-parent-div");
		closeButton = $("#close-toggle-button");
		attendeeNavDiv = $("#attendee-nav-div");
		imageCards = $(".left-image-cards");
		previewImage = $("#previewImage");
		previewSurveyTitle = $("#preview-survey-title");
		previewSurveyQuestion = $("#preview-survey-question");
		previewSurveyTime = $("#preview-survey-time");
		previewSurveyButtonsDiv = $("#preview-survey-buttons");
		previewVerifyButton = $("#preview-verify-button");
		previewRejectButton = $("#preview-reject-button");
		previewundoButtons = $(".preview-undo-button");
		previewVerifiedDiv = $("#preview-verified-div");
		previewRejectedDiv = $("#preview-rejected-div");
		currentSelectedIndex = null;
		totalLength = imageCards.length;
	};

	const _scrollToSelectedItem = function () {
		scrollToElement = clickedDiv.parent();
		position =
			scrollToElement.offset().top - leftDiv.offset().top + leftDiv.scrollTop();
		leftDiv.scrollTop(position);
	};

	const _loadClickedImage = function () {
		var clickedImage = clickedDiv.find("img");
		clickedDiv.attr("id", "clicked-div");
		clickedDiv.css("border", "#3C7D91 5px double");
		previewImage.attr("data-original", clickedImage.attr("data-original"));
		previewImage.lazyload();
		previewSurveyTitle.html(clickedDiv.find("h6").html());
		previewSurveyQuestion.html(clickedDiv.find("p")[0].innerHTML);
		previewSurveyTime.html(clickedDiv.find("p")[1].innerHTML);
		_scrollToSelectedItem();
		_loadImageStatusAndSetUrls();
	};

	const _loadImageStatusAndSetUrls = function () {
		var _responseID = clickedDiv.find("[name='responseId']").val();
		var _clickedDivImageStatus = clickedDiv.find("[name='imageStatus']").val();
		var _verifyButtonUrl =
			"/attendee_survey_images/verify_image?response_id=" + _responseID;
		var _rejectButtonUrl =
			"/attendee_survey_images/reject_image?response_id=" + _responseID;
		_clickedDivImageStatus = parseInt(_clickedDivImageStatus);
		var _undoButtonUrl =
			"/attendee_survey_images/undo_image?response_id=" + _responseID;
		_clickedDivImageStatus = parseInt(_clickedDivImageStatus);
		if (_clickedDivImageStatus === 2) {
			previewVerifyButton.attr("href", _verifyButtonUrl);
			previewRejectButton.attr("href", _rejectButtonUrl);
			previewVerifiedDiv.addClass("d-none");
			previewRejectedDiv.addClass("d-none");
			previewSurveyButtonsDiv.removeClass("previewButtonsDisplay");
		} else if (_clickedDivImageStatus === 1) {
			previewVerifiedDiv.removeClass("d-none");
			previewundoButtons.attr("href", _undoButtonUrl);
			previewSurveyButtonsDiv.addClass("previewButtonsDisplay");
			previewRejectedDiv.addClass("d-none");
		} else if (_clickedDivImageStatus === 0) {
			previewRejectedDiv.removeClass("d-none");
			previewundoButtons.attr("href", _undoButtonUrl);
			previewVerifiedDiv.addClass("d-none");
			previewSurveyButtonsDiv.addClass("previewButtonsDisplay");
		}
	};

	const _toggleEventListeners = function () {
		if (_state == 0) {
			previewVerifyButton.unbind("ajax:success", _onSuccess);
			previewRejectButton.unbind("ajax:success", _onSuccess);
			previewundoButtons.unbind("ajax:success", _onSuccessUndo);
			imageCards.unbind("click");
			closeButton.unbind("click");
			imageCards.on("click", function () {
				App.toggleView(this);
			});
		} else if (_state == 1) {
			imageCards.unbind("click");
			imageCards.on("click", function () {
				clickedDiv.css({ border: "" });
				clickedDiv = $(this);
				currentSelectedIndex = imageCards.index(clickedDiv);
				_loadClickedImage();
			});

			previewVerifyButton.bind("ajax:success", _onSuccess);
			previewRejectButton.bind("ajax:success", _onSuccess);
			previewundoButtons.bind("ajax:success", _onSuccessUndo);

			closeButton.on("click", function () {
				App.toggleView();
			});
		}
	};

	const _onSuccessUndo = function (event, data, xhr) {
		if (data.status) {
			if (data.image_status === 2) {
				clickedDiv.find("[name='imageStatus']").val(data.image_status);
				clickedDiv.children().last().children().last().remove();
				_loadImageStatusAndSetUrls();
			}
		}
	};

	const _onSuccess = function (event, data, xhr) {
		if (data.status) {
			if (data.image_status === 1) {
				clickedDiv
					.find(".card-body")
					.append(
						'<span class="float-right text-success"><i class="fa fa-2x fa-check-circle-o"></i></span>'
					);
			} else {
				clickedDiv
					.find(".card-body")
					.append(
						'<span class="float-right text-danger"><i class="fa fa-ban fa-2x"></i></span>'
					);
			}
			clickedDiv.find("[name='imageStatus']").val(data.image_status);
		}
		clickedDiv.css({ border: "" });
		currentSelectedIndex == totalLength - 1
			? (currentSelectedIndex = 0)
			: (currentSelectedIndex = currentSelectedIndex + 1);
		clickedDiv = $(imageCards.get(currentSelectedIndex));
		_loadClickedImage();
	};

	const _showPreview = function () {
		leftDiv.removeClass("col-12 d-flex flex-row flex-wrap");
		leftDiv.addClass("col-4 image-side d-md-block d-none");
		leftImageWrappers.removeClass("col-lg-4 col-md-6 col-6");
		leftImageWrappers.addClass("col rounded");
		$(".left-image-wrappers:last").removeClass("mb-4");
		rightDiv.removeClass("d-none");
		rightDiv.addClass("col-md-8 border rounded p-0 mx-md-0 mx-1");
		attendeeNavDiv.addClass("previewButtonsDisplay");
		closeButton.removeClass("d-none");
		$("#imageFilter").addClass("previewButtonsDisplay");
	};

	const _hidePreview = function () {
		clickedDiv.css({ border: "" });
		leftDiv.removeClass("col-4 image-side d-md-block d-none");
		leftDiv.addClass("col-12 d-flex flex-row flex-wrap p-0");
		leftImageWrappers.removeClass("col rounded");
		leftImageWrappers.addClass("col-lg-4 col-md-6 col-6");
		rightDiv.removeClass("col-md-8 border rounded p-0 mx-md-0 mx-1");
		rightDiv.addClass("d-none");
		closeButton.addClass("d-none");
		attendeeNavDiv.removeClass("previewButtonsDisplay");
		$("#imageFilter").removeClass("previewButtonsDisplay");
	};

	return {
		toggleView: _toggle,
	};
})();
