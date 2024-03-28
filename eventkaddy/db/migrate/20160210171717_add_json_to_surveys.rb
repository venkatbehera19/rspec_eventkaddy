class AddJsonToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :json, :text, :after => :ends
  end
end
