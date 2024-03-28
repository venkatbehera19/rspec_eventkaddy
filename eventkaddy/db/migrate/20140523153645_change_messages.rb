class ChangeMessages < ActiveRecord::Migration[4.2]
	def up
	    change_column :messages, :content, :text
	end
	def down

	    change_column :messages, :content, :string
	end
end
