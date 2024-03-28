class CreateDomainTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :domain_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :domain_types, :name, :unique => true
  end
end
