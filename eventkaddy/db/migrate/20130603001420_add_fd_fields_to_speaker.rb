class AddFdFieldsToSpeaker < ActiveRecord::Migration[4.2]
  def change
  
  	add_column :speakers, :fd_tax_id, :string
  	add_column :speakers, :fd_pay_to, :string
  	add_column :speakers, :fd_street_address, :string
  	add_column :speakers, :fd_city, :string
  	add_column :speakers, :fd_state, :string
  	add_column :speakers, :fd_zip, :string

  end
end
