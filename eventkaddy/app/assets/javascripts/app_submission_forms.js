$.fn.filepond.registerPlugin(
	FilePondPluginFileValidateSize,
	FilePondPluginImageValidateSize,
	FilePondPluginFileValidateType,
	FilePondPluginImageResize,
	FilePondPluginImageTransform,
	FilePondPluginImagePreview
);

// Properties common to all the ponds
common_pond_properties = {
	allowDrop: true,
	dropOnElement: true,
	required: true,
	acceptedFileTypes: ["image/png"],
	imageResizeMode: "force",
	allowImageTransform: true,
	imageTransformOutputQuality: 100,
	allowImagePreview: true,
	imageValidateSizeLabelImageSizeTooSmall: "Not the correct size",
	credits: null,
	labelIdle:
		'Drag & Drop your image or <span class="filepond--label-action"> Browse </span>',
};

// Properties common to only icon ponds
common_icon_properties = {
	...common_pond_properties,
	imageValidateSizeMinWidth: 1024,
	imageValidateSizeMinHeight: 1024,
	imageResizeTargetWidth: 1024,
	imageResizeTargetHeight: 1024,
	imageValidateSizeLabelExpectedMinSize: "Required size is {1024} * {1024}",
};

// IOS APP ICON POND
$("#ios-icon-pond").filepond({
	...common_icon_properties,
	name: "app_submission_form[ios_app_icon]",
	className: "ios_icon_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	labelFileLoadError: (response) => {
		return serverResponse;
	},
	files:
		!is_ios_new_record || show_ios_images_on_fail
			? [
					{
						// the server file reference
						source: "ios_app_icon",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "ios",
				"X-Image-Type": "ios_app_icon",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_ios_new_record || show_ios_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "ios_app_icon",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
});

// Android feature graphic pond
$("#android-feature-graphic-pond").filepond({
	...common_pond_properties,
	allowFileSizeValidation: true,
	maxFileSize: "1MB",
	acceptedFileTypes: ["image/png", "image/jpeg"],
	name: "app_submission_form[android_feature_graphic_pond]",
	className: "android_feature_graphic_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	labelFileLoadError: (response) => {
		return serverResponse;
	},
	files:
		!is_android_new_record || show_android_images_on_fail
			? [
					{
						// the server file reference
						source: "android_feature_graphic",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	imageValidateSizeMinHeight: 500,
	imageValidateSizeMinWidth: 1024,
	imageResizeTargetHeight: 500,
	imageResizeTargetWidth: 1024,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "android",
				"X-Image-Type": "android_feature_graphic",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_android_new_record || show_android_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "android_feature_graphic",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
});

// ANDROID APP ICON POND
$("#android-icon-pond").filepond({
	...common_icon_properties,
	name: "app_submission_form[android_app_icon]",
	className: "android_icon_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	files:
		!is_android_new_record || show_android_images_on_fail
			? [
					{
						// the server file reference
						source: "android_app_icon",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "android",
				"X-Image-Type": "android_app_icon",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_android_new_record || show_android_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "android_app_icon",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
});

// Android portrait splash pond
$("#android-portrait-splash-pond").filepond({
	...common_pond_properties,
	name: "app_submission_form[android_portrait_splash_screen]",
	className: "android_portrait_splash_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	files:
		!is_android_new_record || show_android_images_on_fail
			? [
					{
						// the server file reference
						source: "android_portrait_splash_screen",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	imageValidateSizeMinHeight: 1920,
	imageValidateSizeMinWidth: 1080,
	imageResizeTargetHeight: 1920,
	imageResizeTargetWidth: 1080,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "android",
				"X-Image-Type": "android_portrait_splash_screen",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_android_new_record || show_android_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "android_portrait_splash_screen",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
	imageValidateSizeLabelExpectedMinSize: "Required size is {1080} * {1920}",
});

$("#android-landscape-splash-pond").filepond({
	...common_pond_properties,
	name: "app_submission_form[android_landscape_splash_screen]",
	className: "android_landscape_splash_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	files:
		!is_android_new_record || show_android_images_on_fail
			? [
					{
						// the server file reference
						source: "android_landscape_splash_screen",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	imageValidateSizeMinHeight: 1080,
	imageValidateSizeMinWidth: 1920,
	imageResizeTargetHeight: 1080,
	imageResizeTargetWidth: 1920,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "android",
				"X-Image-Type": "android_landscape_splash_screen",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_android_new_record || show_android_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "android_landscape_splash_screen",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
	imageValidateSizeLabelExpectedMinSize: "Required size is {1920} * {1080}",
});

$("#ios-splash-pond").filepond({
	...common_pond_properties,
	name: "app_submission_form[ios_splash_screen]",
	className: "ios_splash_pond",
	labelFileProcessingError: (response) => {
		return serverResponse.message;
	},
	files:
		!is_ios_new_record || show_ios_images_on_fail
			? [
					{
						// the server file reference
						source: "ios_splash_screen",
						// set type to local to indicate an already uploaded file
						options: {
							type: "local",
						},
					},
			  ]
			: null,
	imageValidateSizeMinHeight: 2732,
	imageValidateSizeMinWidth: 2732,
	imageResizeTargetHeight: 2732,
	imageResizeTargetWidth: 2732,
	server: {
		process: {
			url: "/app_submission_form_uploads",
			method: "POST",
			headers: {
				"X-Form-Type": "ios",
				"X-Image-Type": "ios_splash_screen",
				"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
			},
			onerror: (response) => {
				serverResponse = JSON.parse(response);
			},
		},
		load:
			!is_ios_new_record || show_ios_images_on_fail
				? {
						url: "/app_submission_form_uploads",
						method: "get",
						headers: {
							"X-Image-Type": "ios_splash_screen",
							"X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
						},
						onerror: (response) => {
							serverResponse = "File not found";
						},
				  }
				: null,
		revert: null,
		fetch: null,
	},
	imageValidateSizeLabelExpectedMinSize: "Required size is {2732} * {2732}",
});
