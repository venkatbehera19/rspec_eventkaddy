class CreateAdmins < ActiveRecord::Migration[4.2]
  def self.up
    create_table :admins do |t|
	  ## Database authenticatable
	  t.string :email,              :null => false, :default => ""
	  t.string :encrypted_password, :null => false, :default => ""
	
	  ## Recoverable
	  t.string   :reset_password_token
	  t.datetime :reset_password_sent_at
	
	  ## Rememberable
	  t.datetime :remember_created_at
	
	  ## Trackable
	  t.integer  :sign_in_count, :default => 0
	  t.datetime :current_sign_in_at
	  t.datetime :last_sign_in_at
	  t.string   :current_sign_in_ip
	  t.string   :last_sign_in_ip
	
	  ## Encryptable
	  # t.string :password_salt
	
	  ## Confirmable
	  # t.string   :confirmation_token
	  # t.datetime :confirmed_at
	  # t.datetime :confirmation_sent_at
	  # t.string   :unconfirmed_email # Only if using reconfirmable
	
	  ## Lockable
	  # t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
	  # t.string   :unlock_token # Only if unlock strategy is :email or :both
	  # t.datetime :locked_at
	
	  # Token authenticatable
	  # t.string :authentication_token
	
	  ## Invitable
	  # t.string :invitation_token
	
	  t.timestamps
    end
  end

  def self.down
    drop_table :admins
  end
end
