class AddPosterNumberToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :poster_number, :string, :after => :session_code
  end
end
