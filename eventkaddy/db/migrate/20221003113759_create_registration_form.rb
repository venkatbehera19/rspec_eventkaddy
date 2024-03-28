class CreateRegistrationForm < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_forms do |t|
      t.integer :event_id
      t.string :email
      t.string :password, default: ''
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :honor_prefix
      t.string :honor_suffix
      t.string :business_unit
      t.string :title
      t.string :business_phone
      t.string :mobile_phone
      t.string :company
      t.string :twitter_url
      t.string :facebook_url
      t.string :linked_in
      t.string :biography
      t.string :country
      t.string :state
      t.string :city
      t.string :custom_filter_3
      t.string :custom_fields_1
      t.string :custom_fields_2
      t.string :custom_fields_3

      t.timestamps
    end
  end
end
