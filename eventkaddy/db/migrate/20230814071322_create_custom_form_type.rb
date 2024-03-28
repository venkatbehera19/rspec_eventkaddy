class CreateCustomFormType < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_form_types do |t|
      t.string :name
      t.string :iid, index: { unique: true, name: 'unique_iid' }
      t.timestamps
    end
  end
end
