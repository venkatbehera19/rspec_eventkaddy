class AddIsVerifiedToResponses < ActiveRecord::Migration[6.1]
  def change
    add_column :responses, :image_status, :integer, default: 2
  end
end
