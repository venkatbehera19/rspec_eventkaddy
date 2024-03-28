class CreateSponsorLevelTypeProductTable < ActiveRecord::Migration[6.1]
  def change
    create_table :sponsor_level_type_products do |t|

      t.references :product
      t.references :sponsor_level_type
      t.timestamps
    end
  end
end
