class CreateExhibitorSponsorLevelType < ActiveRecord::Migration[6.1]
  def change
    create_table :exhibitor_sponsor_level_types do |t|

      t.references :exhibitor
      t.references :sponsor_level_type
      t.timestamps
    end
  end
end
