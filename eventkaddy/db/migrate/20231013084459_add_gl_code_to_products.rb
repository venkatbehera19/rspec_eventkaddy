class AddGlCodeToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :gl_code, :string
  end
end
