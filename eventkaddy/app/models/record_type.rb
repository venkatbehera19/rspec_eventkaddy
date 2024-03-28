class RecordType < ApplicationRecord

  # record type the table having the same name as the association column
  # causes many issues is it is better just to get associated records the
  # hard way
	# has_many :sessions
	
end
