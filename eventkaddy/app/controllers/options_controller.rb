class OptionsController < ApplicationController

  def destroy
    @option = Option.find params[:option_id]
    @option.destroy
    redirect_to edit_poll_url(params[:id])
  end
  
end
