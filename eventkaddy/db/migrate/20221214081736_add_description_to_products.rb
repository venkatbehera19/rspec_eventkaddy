class AddDescriptionToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :description, :text, :after => 'name'
  end
end
