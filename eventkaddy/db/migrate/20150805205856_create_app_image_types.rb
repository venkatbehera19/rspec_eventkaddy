class CreateAppImageTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :app_image_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
