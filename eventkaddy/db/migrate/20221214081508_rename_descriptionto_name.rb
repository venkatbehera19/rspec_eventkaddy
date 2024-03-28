class RenameDescriptiontoName < ActiveRecord::Migration[6.1]
  def change
    rename_column :products, :description, :name
    change_column :products, :name, :string
  end
end
