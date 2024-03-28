class AddEmailerNameToEvent < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :mailer_name, :string
  end
end
