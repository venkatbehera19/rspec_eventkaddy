class AddColsToSpeaker < ActiveRecord::Migration[4.2]
  def change

  	add_column :speakers, :middle_initial, :string
  	add_column :speakers, :notes, :text
  	add_column :speakers, :address1, :string
  	add_column :speakers, :address2, :string
  	add_column :speakers, :address3, :string
  	add_column :speakers, :city, :string
  	add_column :speakers, :state, :string
  	add_column :speakers, :country, :string
  	add_column :speakers, :zip, :string
  	add_column :speakers, :work_phone, :string
  	add_column :speakers, :mobile_phone, :string
  	add_column :speakers, :home_phone, :string
  	add_column :speakers, :fax, :string
  	
  end
end
