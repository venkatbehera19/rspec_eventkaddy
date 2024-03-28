module EmailTemplateMethods
	module ClassMethods
		def remove_html_tags string
			string.gsub(/<.*?>/,'') # non-greedy match all between <>
		end

		def default_email_subject klass_id, type_name
			event = Event.find( klass_id )
			event_name = event.name
			org_name = event.organization.name
			case type_name
			when 'attendee_email_password_template' ; "Your password for the #{event_name} App"
			when 'attendee_email_confirmation_template' ; "Please verify your email"
			when 'speaker_email_confirmation_template' ; "Please verify your email"
			when 'speaker_numeric_password_template' ; "Your password for the #{event_name} Speaker Portal"
			when 'speaker_email_password_template'  ; "Your password for the #{event_name} Speaker Portal"
			when 'exhibitor_email_password_template'; "Your password for the #{event_name} Exhibitor Portal"
			when 'member_subscribe_email_template'; "Thanks for showing Your interest on #{org_name}"
			when 'member_unsubscribe_email_template'; "Thanks for showing Your interest on #{org_name}"
			when 'registration_attendee_receipt_template'; "Thanks for purchasing for the #{event_name} Attendee Portal"
			when 'attendee_refund_template'; "Your refund for purchasing for the #{event_name} Attendee Portal"
			when 'attendee_refund_complete_template'; "Your refund for purchasing for the #{event_name} Attendee Portal"
			when 'exhibitor_receipt_template'; "Thanks for purchasing for the #{event_name} Exhibitor Portal"
			else; event_name
			end
		end

		def default_content event_id, type_name
			#event_id not being used
			case type_name
			when 'attendee_email_password_template'
				<<-eos
				<p>Hi {{attendee.email}},</p>\r\n
	\r\n
					<p>Your password for the upcoming {{event.name}} App is {{attendee.password}}. Use it in combination with your email to access everything you need to know about {{event.name}} directly from your phone!</p>\r\n
	\r\n
					<p>Have a great day!</p>\r\n
				eos
			when 'speaker_email_password_template'
				<<-eos
					<h3>{{event.name}} Speaker Portal</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Speaker Portal. This portal allows you to upload your contact details, session information, and upload session related files. You will also find speaker documentation to download.</p>\r\n
	\r\n
					<p>To login, please use your email address.</p>\r\n
	\r\n
					Your username is your email: {{user.email}}<br>\r\n
					Your password is: {{extras.password}}<br><br>\r\n
	\r\n
					<p>To access the portal, please follow this link: <a href='https://www.eventkaddy.net'>https://www.eventkaddy.net</a></p>\r\n
				eos
			when 'registration_attendee_email_password_template'
				<<-eos
					<h3>{{event.name}} Attendee Portal</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Attendee Portal. This portal allows you to upload your contact details, session information, and upload session related files. You will also find speaker documentation to download.</p>\r\n
	\r\n
					<p>To login, please use your email address.</p>\r\n
	\r\n
					Your username is your email: {{attendee.email}}<br>\r\n
					Your password is: {{extras.password}}<br><br>\r\n
	\r\n
					<p>To access the portal, please follow this link: <a href='https://www.eventkaddy.net'>https://www.eventkaddy.net</a></p>\r\n
				eos
			when 'speaker_numeric_password_template'
				<<-eos
					<h3>{{event.name}} Speaker Portal</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Speaker Portal. This portal allows you to upload your contact details, session information, and upload session related files. You will also find speaker documentation to download.</p>\r\n
	\r\n
					<p>To login, please use your email address.</p>\r\n
	\r\n
					Your username is your email: {{speaker.email}}<br>\r\n
					Your password is: {{extras.password}}<br><br>\r\n
	\r\n
					<p>To access the portal, please follow this link: <a href='https://www.eventkaddy.net'>https://www.eventkaddy.net</a></p>\r\n
				eos
			when 'registration_attendee_confirmation_email_template'
				<<-eos
				<p>Hi {{attendee.email}},</p>\r\n
	\r\n
					<p>Please verify you email address to complete your registration by clicking this link: ADD or DRAG LINK from above </p>\r\n
				eos
			when 'exhibitor_email_password_template'
				<<-eos
					<h3>{{event.name}} Exhibitor Portal</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Exhibitor Portal. This portal allows you to upload contact details and company logo and access vendor exhibit information. You will also find exhibitor documentation to download.</p>\r\n
	\r\n
					<p>To login, please use your email address.</p>\r\n
	\r\n
					Your username is your email: {{user.email}}<br>\r\n
					Your password is: {{extras.password}}<br><br>\r\n
	\r\n
					<p>To access the portal, please follow this link: <a href='https://www.eventkaddy.net'>https://www.eventkaddy.net</a></p>\r\n
				eos
			when 'attendee_email_confirmation_template'
				<<-eos
				<p>Hi {{attendee.email}},</p>\r\n
	\r\n
					<p>Please verify you email address to complete your registration by clicking this link: ADD or DRAG LINK from above </p>\r\n
				eos
			when 'speaker_email_confirmation_template'
				<<-eos
				<p> Hi {{speaker.email}} </p>\r\n
	\r\n
				<p> Please verify your email address to complete your registration by clicking this link: ADD or DRAG LINK from above </p>\r\n
				eos
			when 'calendar_invitation_email_template'
				<<-eos
				<p>Hi {{attendee.email}},</p>\r\n
	\r\n
					<p>Thank you for signing up. The meeting information is below along with the calendar invitation. We will also send out a reminder the day before the meeting.</p>\r\n
				eos
			when 'member_subscribe_email_template'
				<<-eos
				<p>Hi {{user.email}},</p>\r\n
	\r\n
					<p>Thank you for signing up. The meeting information is below along with the calendar invitation. We will also send out a reminder the day before the meeting.</p>\r\n
				eos
			when 'member_unsubscribe_email_template'
				<<-eos
				<p>Hi {{user.email}},</p>\r\n
	\r\n
					<p>Thank you for signing up. The meeting information is below along with the calendar invitation. We will also send out a reminder the day before the meeting.</p>\r\n
				eos
			when 'registration_attendee_receipt_template'
				<<-eos
					<h3>{{attendee.name}}</h3>\r\n
					<h3>{{attendee.account_code}}</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Attendee Portal.</p>\r\n
	\r\n
				eos
			when 'attendee_refund_template'
				<<-eos
					<h3>Hi, {{attendee.name}}</h3>\r\n
					<h3>{{attendee.account_code}}</h3>\r\n
	\r\n
					<p>Your refund amount of {{transaction.amount}} was initiated. You will receive the refund between 3-5 days, depending on your credit card company.</p>\r\n
	\r\n
				eos
			when 'attendee_refund_complete_template'
				<<-eos
					<h3>Hi, {{attendee.name}}</h3>\r\n
					<h3>{{attendee.account_code}}</h3>\r\n
	\r\n
					<p>Your refund in the amount of {{transaction.amount}} has been successfully processed and credited to your account.Thank you for your prompt attention.</p>\r\n
	\r\n
				eos
			when 'exhibitor_receipt_template'
				<<-eos
					<h3>{{exhibitor.name}}</h3>\r\n
					<h3>{{exhibitor.account_code}}</h3>\r\n
	\r\n
					<p>Welcome to the {{event.name}} Exhibitor Portal.</p>\r\n
	\r\n
				eos
			end
		end
	end

	module InstanceMethods
		def render objects
			data = objects.
				map {|o| o.is_a?(ApplicationRecord) ? o.as_json(:root => true).deep_symbolize_keys : o.deep_symbolize_keys }.
				reduce({}, &:merge)
			# allow some preprocessing to be done for specific context specific
			# areas... ie rending images as attachments vs rendering them as just
			# image_tags
			(block_given? ? yield(content) : content).
				gsub(/{{(.*?)\.(.*?)}}/) {|match|
					data[ $1.to_sym ] && data[ $1.to_sym ][ $2.to_sym ] || ""
				}.
				html_safe
		end
	end

	def self.included(receiver)
		receiver.extend         ClassMethods
		receiver.send :include, InstanceMethods
	end
end
