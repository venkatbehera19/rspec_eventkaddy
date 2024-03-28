class AddEnabledToHomeButtons < ActiveRecord::Migration[4.2]
	def change
		add_column :home_buttons, :enabled, :boolean
	end
end