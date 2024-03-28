class AddFinancialDisclosureToSpeaker < ActiveRecord::Migration[4.2]
  def change

  	add_column :speakers, :financial_disclosure, :text
  end
end
