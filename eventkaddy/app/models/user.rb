class User < ApplicationRecord

  devise :two_factor_authenticatable,:two_factor_backupable,otp_backup_code_length: 10, otp_number_of_backup_codes: 10,:otp_secret_encryption_key => Rails.application.credentials.OTP_SECRET_KEY
	# Include default devise modules. Others available are:
	# :confirmable,:registerable, :lockable and :timeoutable
	# devise :confirmable,:lockable,:recoverable, :rememberable, :trackable, :validatable #,:token_authenticatable
	devise :lockable,:recoverable, :rememberable, :trackable, :validatable, :confirmable

	has_many :users_roles, :dependent => :destroy
	# has_many :roles, :through => :users_roles
	has_and_belongs_to_many :roles, :join_table => :users_roles

	has_many :users_events, :dependent => :destroy
	has_many :users_organizations, :dependent => :destroy # this table is never used

	# has_many :events, :through => :users_events
	has_and_belongs_to_many :events, :join_table => :users_events

	has_many :organizations, :through => :users_organizations
	has_many :session_file_versions
  has_many :exhibitors
  has_one  :attendee, :dependent => :destroy
	has_one  :trackowner
  has_one  :cart
  has_many :orders
  has_many :speakers
  has_many :download_requests

	#validates :email,
    #        :presence => true,
    #        :uniqueness => true
    #        :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i }

  validates :email, :uniqueness => true
  validates_length_of :first_name, minimum: 2, maximum: 20, allow_blank: true
  validates_length_of :last_name, minimum: 2, maximum: 20, allow_blank: true
  before_save :to_lower
  before_create :check_for_registrable

  # Ensure that backup codes can be serialized
  serialize :otp_backup_codes, JSON
  serialize :json, JSON
  attr_accessor :otp_plain_backup_codes
  attr_accessor :with_two_factor
  attr_accessor :skip_password_validation, :enable_confirmations
  attr_accessor :mobile_phone, :company, :twitter_url, :facebook_url, :linked_in, :country, :state, :city
  attr_accessor :title
  attr_accessor :client_iid, :client_digest

  def create_order_for_attendee
    order = self.orders.new(status: "Pending")
    order.save

    total = 0
    self.cart.cart_items.each do |item|
      if item.item_type == 'Product'
        order_item = order.order_items.new(
          item_id: item.item_id,
          item_type: item.item_type,
          name: item.item.name,
          price: self.is_member ? item.item.member_price : item.item.price,
          quantity: item.quantity
        )
        if item.size?
          order_item.size = item.size
        end
        total = total + (self.is_member ? item.item.member_price * item.quantity : item.item.price * item.quantity )
        available_quantity = item.item.available_qantity - item.quantity
        item.item.update_column(:available_qantity, available_quantity)
      else
        order.order_items.new(
          item_id: item.item_id,
          item_type: item.item_type,
          name: item.item.products.first.name,
          price: self.is_member ? item.item.products.first.member_price : item.item.products.first.price,
          quantity: item.quantity
        )
        total = total + (self.is_member ? item.item.products.first.member_price * item.quantity : item.item.products.first.price * item.quantity)
        available_quantity = item.item.available_qantity - item.quantity
        item.item.update_column(:available_qantity, available_quantity)
      end
    end
    order.total = total
    order.save
    self.cart.cart_items.delete_all
    order
  end

  def create_order_for_exhibitor
    order = self.orders.new(status: "Pending")
    order.save

    total = 0
    self.cart.cart_items.each do |cart_item|
      if cart_item.item_type == 'Product'
        discount_allocation = cart_item.discount_allocations.last
        if discount_allocation.present?
          order_item = OrderItem.create(
            item_id:   cart_item.item_id,
            item_type: cart_item.item_type,
            name:      cart_item.item.name,
            quantity:  cart_item.quantity,
            price:     discount_allocation.amount,
            order_id:  order.id
          )
          order_discount_allocation = DiscountAllocation.create(
            amount: discount_allocation.amount,
            complimentary_count: discount_allocation.complimentary_count,
            complimentary_amount: discount_allocation.complimentary_amount,
            discounted_count: discount_allocation.discounted_count,
            discounted_amount: discount_allocation.discounted_amount,
            full_count: discount_allocation.full_count,
            full_amount: discount_allocation.full_amount,
            user_id: discount_allocation.user_id,
            event_id: discount_allocation.event_id,
            order_item_id: order_item.id
          )
          total = total + discount_allocation.amount
        else
          order.order_items.new(
            item_id: cart_item.item_id,
            item_type: cart_item.item_type,
            name: cart_item.item.name,
            price: cart_item.item.price,
            quantity: cart_item.quantity
          )
          total = total + (cart_item.item.price * cart_item.quantity )
        end
      else
        discount_allocation = cart_item.discount_allocations.last
        if discount_allocation.present?
          order_item = OrderItem.create(
            item_id: cart_item.item_id,
            item_type: cart_item.item_type,
            name: cart_item.item.products.first.name,
            price: discount_allocation.amount,
            quantity: cart_item.quantity,
            order_id: order.id
          )
          DiscountAllocation.create(
            amount: discount_allocation.amount,
            full_count: discount_allocation.full_count ,
            full_amount: discount_allocation.full_amount,
            user_id: discount_allocation.user_id,
            event_id: discount_allocation.event_id,
            order_item_id: order_item.id,
          )
          total = total + discount_allocation.amount
        else
          order.order_items.new(
            item_id: cart_item.item_id,
            item_type: cart_item.item_type,
            name: cart_item.item.products.first.name,
            price: cart_item.item.products.first.price,
            quantity: cart_item.quantity
          )
          total = total + (cart_item.item.products.first.price * cart_item.quantity)
        end
      end
    end
    order.total = total
    order.status = "Pending"
    order.save
    # cart.cart_items.delete_all
    order
  end

  def self.serialized_attr_accessor props
    props.each do |method_name|
      eval "
        def #{method_name}
          (self.json || {})['#{method_name}']
        end
        def #{method_name}=(value)
          self.json ||= {}
          self.json['#{method_name}'] = value
        end
      "
    end
  end

  serialized_attr_accessor [:title, :is_subscribed]

  def with_two_factor
    @with_two_factor || false
  end

  # enable confirmable for only superadmin and client
  def check_for_registrable
    self.skip_confirmation! if enable_confirmations.nil?
  end


  # Generate an OTP secret it it does not already exist
  def generate_two_factor_secret_if_missing!
    return unless otp_secret.nil?
    update!(otp_secret: User.generate_otp_secret)
  end

  # Ensure that the user is prompted for their OTP when they login
  def enable_two_factor!
    update!(otp_required_for_login: true)
  end

  #remove existng backup codes on reset2FA
  def remove_existing_backup_codes!
    update!(otp_backup_codes: nil)
  end

  # Disable the use of OTP-based two-factor.
  def disable_two_factor!
    update!(
        otp_required_for_login: false,
        otp_secret: nil,
        otp_backup_codes: nil
      )
  end

  # URI for OTP two-factor QR code
  def two_factor_qr_code_uri
    issuer = Rails.application.credentials.OTP_2FA_ISSUER_NAME
    label  = [issuer, email].join(':')

    otp_provisioning_uri(label, issuer: issuer)
  end

  # Determine if backup codes have been generated
  def two_factor_backup_codes_generated?
    otp_backup_codes.present?
  end


  def active_for_authentication?
    super && !deactivated
  end

  def inactive_message
    !deactivated ? super : :account_inactive
  end

  def to_lower
    self.email = self.email.downcase
  end

  def role?(role)
    !!self.roles.find_by_name(role.to_s.camelize)
  end

  def is_a_staff?
    ExhibitorStaff.exists?(user_id: self.id, is_exhibitor:false)
  end

  def is_exhibitor_and_nothing_else?
    u_roles = roles.pluck(:name)
    u_roles.length == 1 && u_roles[0] == 'Exhibitor'
  end

  def is_exhibitor_and_nothing_else_or_nothing?
    u_roles = roles.pluck(:name)
    return true if roles.length == 0
    u_roles.length == 1 && u_roles[0] == 'Exhibitor'
  end

  def is_speaker_and_nothing_else?
    u_roles = roles.pluck(:name)
    u_roles.length == 1 && u_roles[0] == 'Speaker'
  end

  def is_speaker_and_nothing_else_or_nothing?
    u_roles = roles.pluck(:name)
    return true if roles.length == 0
    u_roles.length == 1 && u_roles[0] == 'Speaker'
  end

  def is_trackowner_and_nothing_else_or_nothing?
    u_roles = roles.pluck(:name)
    return true if roles.length == 0
    u_roles.length == 1 && u_roles[0] == 'TrackOwner'
  end

  def allowed_to_remote_sign_in?
    is_exhibitor_and_nothing_else? && users_events.pluck(:event_id).include?(155)
  end

  # def send_confirmation_notification?
  #   skip_confirmation_notification! if enable_confirmation_mailer.nil?
  #   confirmation_required? && !@skip_confirmation_notification && self.email.present?
  # end

  def generate_token
    self.confirmation_token = loop do
      random_token = SecureRandom.urlsafe_base64(15, false)
      break random_token unless Attendee.exists?(token: random_token)
    end
    # SecureRandom.urlsafe_base64(15).to_s
  end

  def generate_confirmation_instructions!
    self.confirmation_token = generate_token
    self.confirmation_sent_at = Time.now
    self.save
  end

  def generate_two_factor_token!
    self.reset_two_factor_token = loop do
      random_token = SecureRandom.urlsafe_base64(15, false)
      break random_token unless User.exists?(reset_two_factor_token: random_token)
    end
    save!
  end

  def activate_user
    self.update!(deactivated: false)
  end

  def deactivate_user
    self.update!(deactivated: true)
  end

  def confirm_user
    self.update!(confirmed_at: Time.now)
  end

  # TODO: can we deprecate this?
  def eventHasPortal(event_id) # this method would probably be better just reading a yaml file
    event = Event.find(event_id)
    event.domains.length > 0
  end

  # TODO: not sure this is still in use, may want to deprecate
  def grantSpeakerPortalAccess(event_id, params) # this method also updates a user's password

		status = false

		users = User
      .joins('LEFT JOIN users_roles ON users_roles.user_id=users.id
		          LEFT JOIN roles ON users_roles.role_id=roles.id')
		  .where('users.email=? AND roles.name= ?', self.email, 'Speaker')

		if users.length == 0 #no existing user account, grant access

      role = Role.where(name:"Speaker").first
	  	if self.save
        status    = true
        user_role = UsersRole.new({role_id:role.id, user_id:self.id})
        user_role.save
        # add association between user and event
				users_event = UsersEvent.where(user_id: self.id, event_id: event_id).first_or_initialize
				users_event.save
        speaker = Speaker.where(email: self.email).first
        SpeakerMailer.speaker_email_password(event_id, speaker, params).deliver
        # UserMailer.send_password_confirmation(self, event_id, params[:user][:password).deliver
        # UserMailer.manual_password_change(self,params[:user][:password],true).deliver
      end

    elsif users.length == 1 #update password

      #add association between user and event
			users_event = UsersEvent.where(user_id:self.id,event_id:event_id).first_or_initialize
			users_event.save()

      if self.update!(params[:user])
        status = true
        UserMailer.manual_password_change(self,params[:user][:password],false).deliver
      end
		end

    if status == true
      #update the speaker's email address
      speaker = Speaker.find(params[:speaker_id]).update!({email:self.email})
    end

		status
  end

  # TODO: this is used in the speaker portal for changing the speakers email, but it
  # should probably be deprecated and replaced with something less confusing
  def updateSpeakerRow(params)
    @speaker       = Speaker.where(email:original_email).first
    @speaker.email = email
    @speaker.save
  end

  def first_or_create_exhibitor event_id
    raise "User #{email} does not have exhibitor role." unless role? 'exhibitor'
    # Or we could just create it. Since you're led to a portal based on your role,
    # there isn't a usecase for this yet.
    # unless role? 'exhibitor'
    #   UserRole.create(user_id: id, role_id:Role.where(name:"Exhibitor").first)
    # end

    #Default sponsor level type for exhibitor is set to General
    sponsor_level_type_id = SponsorLevelType.where(sponsor_type: 'General').first.id
    exhibitor_by_user_id(event_id) ||
      exhibitor_by_email(event_id) ||
      Exhibitor.create( user_id: id, email: email, event_id: event_id,
         sponsor_level_type_id: sponsor_level_type_id )
  end

  # TODO: this should not ever update an exhibitor's user_id to be a super admin user's id
  #
  # It's not actually a huge security hole because they can't change the super
  # admin's password or use his account, but it's still iffy.
  #
  # There would be a performance hit in imports if we validated the email before every save
  #
  def exhibitor_by_email event_id
    e = Exhibitor.where(email: email, event_id: event_id).first
    if e
      e.update!(user_id: id) unless e.user_id
      e
    else
      nil
    end
  end

  def exhibitor_by_user_id event_id
    Exhibitor.where(user_id: id, event_id: event_id).first
  end

  def self.first_or_create_for_exhibitor exhibitor, password, allow_update_password=true
    return false if exhibitor.email.blank?
    return false if password.blank?

    # this is slightly tricky to read. The where is only on the email; the
    # first_or_create will add the password. In a way it's convenient, but it's
    # also easy to misunderstand
    user = where(email:exhibitor.email).first_or_create(
      email:    exhibitor.email,
      password: password
    )

    raise "Password was not valid (must be at least 6 characters)" if password.to_s.length < 6

    # if we try to do with already created user with diffrent
    # roles thhen it will break
    # unless user.is_exhibitor_and_nothing_else_or_nothing?
    #   raise 'User must only be exhibitor role.'
    # end

    role_id = Role.where(name: 'Exhibitor').first.id

    UsersRole
      .where(user_id:user.id, role_id:role_id)
      .first_or_create

    users_event = UsersEvent
      .where(user_id:user.id, event_id:exhibitor.event_id)
      .first_or_create

    UserEventRole
      .where(users_event_id: users_event.id, role_id: role_id)
      .first_or_create

    # doesn't invoke callbacks, ie before_save etc
    exhibitor.update_column(:user_id, user.id)

    if allow_update_password
      user.update! password: password
      raise user.errors.inspect if user.errors.any?
    end

    user
  end

  def first_or_create_speaker event_id
    raise "User #{email} does not have speaker role." unless role? 'speaker'
    # Or we could just create it. Since you're led to a portal based on your role,
    # there isn't a usecase for this yet.
    # unless role? 'speaker'
    #   UserRole.create(user_id: id, role_id:Role.where(name:"Speaker").first)
    # end
    speaker_by_user_id(event_id) ||
      speaker_by_email(event_id) ||
      Speaker.create( user_id: id, email: email, event_id: event_id )
  end

  def speaker_by_email event_id
    e = Speaker.where(email: email, event_id: event_id).first
    if e
      e.update!(user_id: id) unless e.user_id
      e
    else
      nil
    end
  end

  def speaker_by_user_id event_id
    Speaker.where(user_id: id, event_id: event_id).first
  end

  def first_or_create_trackowner event_id
    raise "User #{self.email} does not have trackowner role." unless self.role? :trackowner

    trackowner_by_user_id(event_id) || trackowner_by_email(event_id) ||
      Trackowner.create!(user_id: self.id, email: self.email, event_id: event_id)
  end

  def trackowner_by_email event_id
    e = Speaker.where(email: self.email, event_id: event_id).first
    if e
      e.update!(user_id: self.id) unless e.user_id
      e
    else
      nil
    end
  end

  def trackowner_by_user_id event_id
    Speaker.where(user_id: self.id, event_id: event_id).first
  end

  def self.first_or_create_for_speaker speaker, password, allow_update_password=true
    return false if speaker.email.blank?
    return false if password.blank?

    user = where(email:speaker.email).first_or_create(
      email:    speaker.email,
      password: password
    )

    raise "Password was not valid (must be at least 6 characters)" if password.to_s.length < 6

    if user.first_name.nil? || user.last_name.nil?
      if speaker.first_name.present? && speaker.last_name.present?
        user.first_name = speaker.first_name
        user.last_name  = speaker.last_name
        user.save
      elsif speaker.first_name.present?
        user.first_name = speaker.first_name
        user.save
      elsif speaker.last_name.present?
        user.last_name  = speaker.last_name
        user.save
      end
    end
    # if the user has already created with diffrent roles
    # and try to do with email queue with speaker it gives the issue
    # unless user.is_speaker_and_nothing_else_or_nothing?
    #   raise 'User must only be speaker role.'
    # end

    role_id = Role.where(name: 'Speaker').first.id

    UsersRole
      .where(user_id:user.id, role_id:role_id)
      .first_or_create

    users_event = UsersEvent
      .where(user_id:user.id, event_id:speaker.event_id)
      .first_or_create

    UserEventRole
      .where(users_event_id: users_event.id, role_id: role_id)
      .first_or_create

    # doesn't invoke callbacks, ie before_save etc
    speaker.update_column(:user_id, user.id)

    if allow_update_password
      user.update! password: password
      raise user.errors.inspect if user.errors.any?
    end

    user
  end

  def self.first_or_create_for_trackowner trackowner, password, allow_update_password=true
    return false if trackowner.email.blank?
    return false if password.blank?

    user = where(email:trackowner.email).first_or_create(
      email:    trackowner.email,
      password: password
    )

    raise "Password was not valid (must be at least 6 characters)" if password.to_s.length < 6

    unless user.is_trackowner_and_nothing_else_or_nothing?
      raise 'User must only be trackowner role.'
    end

    role_id = Role.where(name: 'TrackOwner').first.id

    UsersRole
      .where(user_id:user.id, role_id:role_id)
      .first_or_create

    UsersEvent
      .where(user_id:user.id, event_id:trackowner.event_id)
      .first_or_create

    # doesn't invoke callbacks, ie before_save etc
    trackowner.update_column(:user_id, user.id)

    if allow_update_password
      user.update! password: password
      raise user.errors.inspect if user.errors.any?
    end

    user
  end

  def full_name
    return "#{self.first_name} #{self.last_name}"
  end

  protected

  def password_required?
    return false if skip_password_validation
    super
  end

end
