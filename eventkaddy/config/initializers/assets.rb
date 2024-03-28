# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( bootstrap-mailer.css application-mailer.css event_registrations.scss registrations.css registrations.js customized_registrations.scss ckeditor/config unordered-files/sortandrename.js unordered-files/jquery.form.js unordered-files/image_upload.js slots.scss slots.js app_submission_forms.scss file-pond-plugin-image-size-metadata.js app_submission_forms.js attendee_survey_images.js sessions_polls.js program_feed.scss program_feed.js zebra-print.js)

