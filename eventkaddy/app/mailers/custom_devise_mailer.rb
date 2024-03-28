class CustomDeviseMailer < Devise::Mailer
  
 
  # To make sure that your mailer uses the devise views
  default template_path: 'devise/mailer' 

 def confirmation_instructions(record, token, options={})

   # Use different e-mail templates for normal signup e-mail confirmation 
   # and for when a user is invited into the system by an existing user.
   if record.with_two_factor
     options[:template_name] = 'confirmation_instructions_with_two_factor'
   else
     options[:template_name] = 'confirmation_instructions'
   end
   super
  end
end