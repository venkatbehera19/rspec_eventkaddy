Eventkaddy::Application.routes.draw do

  get 'forgot_password/mobile_send_password_reset_confirmation'
  get 'forgot_password/mobile_forgot_password' #has to be get because of txt version of mailer

  get 'forgot' => 'forgot_password#forgot_password_desktop'
  get 'forgot_password/retrieve_password'

end