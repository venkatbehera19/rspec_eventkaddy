module ExceptionHandler extend ActiveSupport::Concern
  included do
#    rescue_from Exception, with: :standard_error
  end

  private

  def standard_error(error)
    flash[:alert] = error.message
    puts "New Exception: #{error.message}".red

    # puts "---------------------------------------------------"
    # puts "Track: #{error.backtrace.join("\n")}".red
    # puts "----------------------------------------------------"
    puts error.message
    redirect_to( request.referer || '/', :alert => error.message)
  end
  
end
