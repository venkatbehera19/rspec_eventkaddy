class SpeakerRegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'speaker_registration'

  def new 
    @speaker = Speaker.new(event_id: params[:event_id])
    @speaker_registration_settings = Setting.return_speaker_registration_settings(params[:event_id])
  end

  def create
    event = Event.where(id: params[:event_id]).first
    
    if event.blank?
      redirect_to "/users/sign_in", alert: "You don't have access"
      return
    end
    
    @speaker_registration_settings = Setting
                                       .return_speaker_registration_settings(
                                         params[:event_id]
                                       )
    
    if @speaker_registration_settings.blank?
      redirect_to "/users/sign_in",
                  alert: "Event has not been configured properly, please check with admin."
      return
    end
    
    if !verify_recaptcha(model: @user)
      @speaker = Speaker.new(
        event_id: params[:event_id], 
        first_name: params[:speaker][:first_name], 
        last_name: params[:speaker][:last_name], 
        email: params[:speaker][:email], 
        company: params[:speaker][:company], 
        title: params[:speaker][:title])
      render :new, alert: 'Invalid Captcha!'
      return
    end
    speaker = Speaker.where(
      event_id: params[:event_id],
      email: params[:speaker][:email]
    ).first
    
    if speaker.present?
      if speaker.confirmed_at.blank?
        speaker.generate_confirmation_token
        speaker.save
        SpeakerMailer.registration_confirmation(params[:event_id], speaker).deliver_now
        flash[:login_notice] = "A confirmation email has been sent your registered email, please check your inbox."
        redirect_to "/#{params[:event_id]}/speaker_registrations/success"
        return
      else
        flash[:login_notice] = 'You already have registered to this event, please try login.'
        redirect_to "/users/sign_in"
        return
      end
    end
    
    speaker = Speaker.new(
      event_id: params[:event_id], 
      first_name: params[:speaker][:first_name], 
      last_name: params[:speaker][:last_name], 
      email: params[:speaker][:email], 
      company: params[:speaker][:company], 
      title: params[:speaker][:title])
    
    user = User.where(
      email: params[:speaker][:email]).first
    
    if speaker.save
      if user.blank?        
        speaker.generate_confirmation_token
        speaker.save
        SpeakerMailer.registration_confirmation(params[:event_id], speaker).deliver_now
        flash[:login_notice] = "A confirmation email has been sent your registered email, please check your inbox."
        redirect_to "/#{params[:event_id]}/speaker_registrations/success"
        return
      else
        speaker.update_column(:user_id, user.id)
        UsersEvent.where(user_id: user.id, event_id: event.id).first_or_create
        speaker_role = Role.where(name: "speaker").first
        UsersRole.where(user_id: user.id, role_id: speaker_role.id).first_or_create
        flash[:login_notice] = "You have been registered to this event, please try login."
        redirect_to "/users/sign_in"
        return
      end
    end
  end

  def confirm
    @speaker = Speaker.find_by_confirmation_token(params[:token])
    @speaker_registration_settings = Setting.return_speaker_registration_settings(@speaker.event_id)
      if !@speaker.confirmed_at.nil?
        # @message = "Email already verified. Please check your email."
        # return
        flash[:login_notice] = "Email already verified. Please check your email."
        redirect_to "/#{params[:event_id]}/speaker_registrations/success" and return
      end
      
      if @speaker.blank? || @speaker.speaker_code != params[:user]
        @message = "Invalid link or link has expired"

      else

        if @speaker_registration_settings&.numeric_password
          password = generate_password
          params[:password] = password
          user = User.new(email: @speaker.email, password: password)

          if user.save
            role = Role.where(name:"Speaker").first
            user_role = UsersRole.new({role_id: role.id, user_id: user.id})
            @speaker.update_column(:confirmed_at, Time.now)
            users_event = UsersEvent.where(user_id: user.id, event_id: @speaker.event_id).first_or_initialize

            if user_role.save

              if users_event.save
                SpeakerMailer.speaker_numeric_password(@speaker.event_id, @speaker, params).deliver
                # @message = "The speaker portal credential has been sent to your email."
                flash[:login_notice] = "The speaker portal credential has been sent to your email."
                redirect_to "/#{params[:event_id]}/speaker_registrations/success" and return
                
              else
                @message = "Something went wrong."
              end

            else
              @message = "Something went wrong."
            end

          else
            @message = "Something went wrong while creating user!."
          end
    
        else
          @user = User.new
        end
      end
  end

  def success 
    
    event_id = params[:event_id]
    @speaker_registration_settings = Setting.return_speaker_registration_settings(event_id)
    # binding.pry
    
  end

  def create_speaker_portal_user    
    if !params[:user][:password].empty? && (params[:user][:password] == params[:user][:password_confirmation])
      if !(params[:user][:password].length >= 8 && params[:user][:password].length < 20)
        @speaker = Speaker.find(params[:speaker_id])
        redirect_to "/speaker_registrations/confirm?token=#{@speaker.confirmation_token}&event_id=#{@speaker.event_id}&user=#{@speaker.speaker_code}", :alert => "Password should be greater than 8 and less then 20 letter"
        return
      end
      users = User.select('users.id').joins('
        LEFT JOIN users_roles ON users_roles.user_id=users.id
        LEFT JOIN roles ON users_roles.role_id=roles.id').where('users.email=? AND roles.name= ?',params[:user][:email],'Speaker')
        
        if users.first.nil? 
          @user = User.new(email: params[:email], password: params[:user][:password])
        else
          @user = User.find(users.first.id)
        end
        
        @speaker = Speaker.find(params[:speaker_id])
                
        if (@user.grantSpeakerPortalAccess(@speaker.event_id, params))
          @message = "Email address verified successfully!"
          @speaker.update_column(:confirmed_at, Time.now)
          current_user = @user
          sign_in(current_user)
          redirect_to '/'
        else
          @message = "You have an account with speaker please login."
        end
        
    else
      @speaker = Speaker.find(params[:speaker_id])
      redirect_to "/speaker_registrations/confirm?token=#{@speaker.confirmation_token}&event_id=#{@speaker.event_id}&user=#{@speaker.speaker_code}", :alert => "Please set the password correctly"
    end

  end

  private

  def speaker_params
    params.require(:speaker).permit(:first_name, :last_name, :email, :title, :company).merge(event_id: params[:event_id])
  end

  def generate_password
    o = ('0'..'9').to_a
    password = ('1'..'9').to_a.sample + (0...5).map { o[rand(o.length)] }.join
    password
  end

end