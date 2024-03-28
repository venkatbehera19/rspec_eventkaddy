class CreateDomains < ActiveRecord::Migration[4.2]
  def change
    create_table :domains do |t|
      t.integer :event_id
      t.integer :domain_type_id
      t.string :domain
      t.string :subdomain

      t.timestamps
    end
    add_index :domains, :domain
    add_index :domains, :subdomain
  end
end
