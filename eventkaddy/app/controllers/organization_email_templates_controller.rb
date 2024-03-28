class OrganizationEmailTemplatesController < ApplicationController
	layout 'subevent_2013'

	def create
		template_type_name = TemplateType.find_by(id: template_params["template_type_id"]).name
		@template = OrganizationEmailTemplate.email_password_template_for( session[:event_id], template_type_name)
		if @template.update(template_params)
			if params[:user_id].present?
				@template.send_mails(params, session[:event_id])
			end
			redirect_to "/settings/#{template_type_name}", notice: "Template Saved"
		else
			redirect_to "/settings/#{template_type_name}", alert: "Something went wrong"
		end
	end

	def destroy_organization_email_file
		org_file = OrganizationFile.find_by(id: params[:id])
		org_file.update_attribute('deleted', true)
    respond_to do |format|
      format.js {render inline: "location.reload();" } #reloads the the page after delete
      format.xml  { head :ok }
    end
	end

	private

	def template_params
		params.require(:organization_email_template).permit(:organization_id, :template_type_id, :email_subject, :content)
	end
end