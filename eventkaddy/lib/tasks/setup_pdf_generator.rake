# Example usage: "rake prawn_pdf:all[Credits_Bear_PDF,78]" will 
# make routes to generate_credits_bear_pdf with a service called 
# GenerateCreditsBearPdf under the module Event78
# and will show up as a button labeled Email Credits Bear PDF
# in the cordova app. A blank pdf will be generated until
# you edit GenerateCreditsBearPdf using the prawn pdf dsl.
namespace :prawn_pdf do

  desc "add routes path for generating pdf"
  task :update_routes, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.create_generator_route args[:event_id], args[:name].downcase
  end

  desc "add requires to initializers"
  task :update_ce_credits_initializers, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.create_ce_credits_require args[:event_id], args[:name]
  end

  desc "add method to ce_credits_controller"
  task :update_ce_credits_controller, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.create_ce_credits_controller_method args[:event_id], args[:name]
  end

  desc "create module namespace and generator class"
  task :create_generator_class, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.create_prawn_pdf_generator_class args[:event_id], args[:name]
  end

  desc "create email script"
  task :create_email_script, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.create_pdf_email_script args[:event_id], args[:name]
  end

  desc "remove routes path from ce_credits_routes"
  task :remove_routes, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.remove_route args[:event_id], args[:name].downcase
  end

  desc "remove require from initializers"
  task :remove_ce_credits_initializers, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.remove_credits_require args[:event_id], args[:name]
  end

  desc "remove certficate method from ce_credits_controller"
  task :remove_ce_credits_controller, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.remove_ce_credits_controller_method args[:event_id], args[:name]
  end

  desc "remove pdf generator class generator class"
  task :delete_generator_class, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.remove_prawn_pdf_generator_class args[:event_id], args[:name]
  end

  desc "remove email script"
  task :delete_email_script, [:name, :event_id] do |t, args|
    CodeAmend::PdfTemplates.remove_pdf_email_script args[:event_id], args[:name]
  end

  desc "remove and delete files from pdf generation in cms"
  task :remove_files, [:name, :event_id] do |t, args|
    Rake::Task['prawn_pdf:remove_routes'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:remove_ce_credits_initializers'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:remove_ce_credits_controller'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:delete_generator_class'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:delete_email_script'].invoke args[:name], args[:event_id]

    puts "-------------------".yellow
    puts "Next Steps:".green
    puts "- restart rails (to activate new route and require statement)".green
  end

  desc "update and create files for pdf generation in cms"
  task :all, [:name, :event_id] do |t, args|
    Rake::Task['prawn_pdf:update_routes'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:update_ce_credits_initializers'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:update_ce_credits_controller'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:create_generator_class'].invoke args[:name], args[:event_id]
    Rake::Task['prawn_pdf:create_email_script'].invoke args[:name], args[:event_id]

    puts "-------------------".yellow
    puts "Next Steps:".green
    puts "- restart rails (to activate new route and require statement)".green
    puts "- edit the pdf generator located in app/services/pdf_generators/event_#{args[:event_id]}/generate_#{args[:name].downcase}.rb".green
    puts "- edit the subject and content of the email in ek_scripts/pdf-generators/#{args[:event_id]}_generate_#{args[:name].downcase}.rb".green
    puts "- add ::#{args[:name]}:: to a custom list item to see it appear in the cordova app.".green
    puts "- double check notifications cron task is still working.".green
  end
end
