class CreateAppFormTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :app_form_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
