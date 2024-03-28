class AddRatingToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :rating, :integer, :after => :response
  end
end
