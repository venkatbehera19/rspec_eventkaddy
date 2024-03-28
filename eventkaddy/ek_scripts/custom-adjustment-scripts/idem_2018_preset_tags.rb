# We received this data as a spreadsheet and I had to prepare it for 
# entry into the database... So I just did some formatting with macros
# to prepare it for our system and update the preset_tags_hash in the
# events table for IDEM 2018

require_relative '../settings.rb'
require 'active_record'
require_relative '../../config/environment.rb'
ActiveRecord::Base.establish_connection(
  adapter:  "mysql2",
  host:     @db_host,
  username: @db_user,
  password: @db_pass,
  database: @db_name
)

preset_tags = {
  "2" => [ 
    ["Company Type", "Academia"],
    ["Company Type", "Dental Chain/Hospital"],
    ["Company Type", "Finance (Bank], Insurance)"],
    ["Company Type", "Importer"],
    ["Company Type", "Laboratory"],
    ["Company Type", "Manufacturer"],
    ["Company Type", "NGO/Association/Government"],
    ["Company Type", "Press/Media"],
    ["Company Type", "Service Provider (EDP/IT], training. Etc)"],
    ["Company Type", "Trading Company"],
    ["Company Type", "Wholesaler/Retailer/Distributors"],

    ["Dental Sector", "Dental Public Health"],
    ["Dental Sector", "Endodontics"],
    ["Dental Sector", "Oral and Maxillofacial Surgery"],
    ["Dental Sector", "Orthodontics"],
    ["Dental Sector", "Periodontics"],
    ["Dental Sector", "Pediatric Dentistry"],
    ["Dental Sector", "Prosthodontics"],
    ["Dental Sector", "Oral Pathology and Oral Medicine"],
    ["Dental Sector", "Geriatrics and Special Needs"],

    ["Product Segment", "Dental Practice", "Digital Dentistry (D)"],
    ["Product Segment", "Dental Practice", "Cosmetic Dentistry"],
    ["Product Segment", "Dental Practice", "Dental Materials"],
    ["Product Segment", "Dental Practice", "Dental Units"],
    ["Product Segment", "Dental Practice", "Implant Dentistry"],
    ["Product Segment", "Dental Practice", "Instruments, Handpieces and Tools for the Practice"],
    ["Product Segment", "Dental Practice", "Pharmaceuticals"],
    ["Product Segment", "Dental Practice", "Practice Equipment"],
    ["Product Segment", "Dental Practice", "Practice Furniture"],
    ["Product Segment", "Dental Practice", "Special Devices"],
    ["Product Segment", "Dental Practice", "Prophylaxis/Dental and Oral Hygiene"],
    ["Product Segment", "Dental Practice", "Work Aids and Auxiliary Materials for Dental Treatment"],

    ["Product Segment", "Dental Laboratory", "Digital Dentistry (L)"],
    ["Product Segment", "Dental Laboratory", "Instruments, Handpieces and Tools for the Laboratory"],
    ["Product Segment", "Dental Laboratory", "Laboratory Equipment and Systems"],
    ["Product Segment", "Dental Laboratory", "Laboratory Furniture"],
    ["Product Segment", "Dental Laboratory", "Materials for Denture, Models, Inlays, Crowns and Bridges"],
    ["Product Segment", "Dental Laboratory", "Orthodontic (Re-) Construction Auxiliaries"],
    ["Product Segment", "Dental Laboratory", "CAD/CAM blocks, Mouldings, Artificial teeth"],
    ["Product Segment", "Dental Laboratory", "Work Aids and Materials for Dental Laboratory"],

    ["Product Segment", "Infection Control and Maintenance", "Disinfectants (Chemical)"],
    ["Product Segment", "Infection Control and Maintenance", "Professional and Protective Clothing"],
    ["Product Segment", "Infection Control and Maintenance", "Sterilization/Disinfectant Devices and Auxiliaries"],

    ["Product Segment", "Services, Information, Communication and Organization", "Associations/Training and education"],
    ["Product Segment", "Services, Information, Communication and Organization", "Banks, Insurance"],
    ["Product Segment", "Services, Information, Communication and Organization", "Software & IT-Solutions"],
    ["Product Segment", "Services, Information, Communication and Organization", "Media/Publications"],
    ["Product Segment", "Services, Information, Communication and Organization", "Other Services"],

    ["Looking for Agents", "Singapore"],
    ["Looking for Agents", "Indonesia"],
    ["Looking for Agents", "Malaysia"],
    ["Looking for Agents", "Thailand"],
    ["Looking for Agents", "Vietnam"],
    ["Looking for Agents", "Myanmar"],
    ["Looking for Agents", "Cambodia"],
    ["Looking for Agents", "Laos"],
    ["Looking for Agents", "Australia/New Zealand"],
    ["Looking for Agents", "South Korea"],
    ["Looking for Agents", "Japan"],
    ["Looking for Agents", "Hong Kong/Taiwan"],
    ["Looking for Agents", "China"],
    ["Looking for Agents", "India"],
    ["Looking for Agent", "Middle East"],
    ["Looking for Agent", "Europe"],
    ["Looking for Agent", "North America"],
    ["Looking for Agent", "South America"],
    ["Looking for Agent", "Africa"]

  ]
}

Event.find(155).update! tag_sets_hash: preset_tags.as_json
