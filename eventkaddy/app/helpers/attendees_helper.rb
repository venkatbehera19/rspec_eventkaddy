module AttendeesHelper

 	def add_reports_to_certificate_dropdown(certificates)
 		## not saving the data, only to add report to dropdown
 		certificates << CeCertificate.new(name: "Lead Survey Report")
 		certificates
 	end

end
