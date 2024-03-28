namespace :create_initial_record do
  # desc "Create Mode Of Payement Record"
  # task :create_mode_of_payment => :environment do
  #   ModeOfPayment.find_or_create_by(name: 'Paypal')
  # end

  desc "Create Transaction Status Type"
  task :create_transaction_status_type => :environment do
    TransactionStatusType.find_or_create_by(iid: 'pending', description: "Transaction Started & In Process")
    TransactionStatusType.find_or_create_by(iid: 'failed', description: "Transaction Failed")
    TransactionStatusType.find_or_create_by(iid: 'success', description: "Transaction Complete")
  end

  desc "Create Product Category"
  task :create_product_category, [:event_id] => :environment do |t, args|
    ProductCategory.find_or_create_by(iid: 'registration', name: "Registration", event_id: args[:event_id])
  end

  desc "Create Product For SDAFP Event"
  task :create_registration_products, [:event_id] => :environment do |t, args|
    registration_category = ProductCategory.registration(args[:event_id])

    Product.find_or_create_by(iid: 'aafp_member', description: 'AAFP Member', event_id: args[:event_id], product_category: registration_category, price: 495.00 )

    Product.find_or_create_by(iid: 'aafp_non_member', description: 'AAFP Non-Member', event_id: args[:event_id], product_category: registration_category, price: 550.00 )

    Product.find_or_create_by(iid: 'aafp_retired', description: 'AAFP Retired', event_id: args[:event_id], product_category: registration_category, price: 450.00 )

    Product.find_or_create_by(iid: 'aafp_health_professional', description: 'Allied Health Professional (i.e. Pharm, RN, NP, PA)', event_id: args[:event_id], product_category: registration_category, price: 400 )

    Product.find_or_create_by(iid: 'medical_resident', description: 'Medical Resident', event_id: args[:event_id], product_category: registration_category, price: 100.00 )

    Product.find_or_create_by(iid: 'medical_student', description: 'Medical Student', event_id: args[:event_id], product_category: registration_category, price: 75.00 )

  end

  desc "Create PayPal Mode Of Payement Record For Event"
  task :create_paypal_mode_of_payment_for_event, [:event_id] => :environment do |t, args|
    ModeOfPayment.where(event_id: nil).destroy_all
    ModeOfPayment.find_or_create_by(name: 'PayPal', event_id: args[:event_id])
  end

  desc "Create PDF Type Home Button Type"
  task :create_pdf_home_button_type => :environment do
    HomeButtonType.find_or_create_by(name: "PDF", standard: false)
  end

end