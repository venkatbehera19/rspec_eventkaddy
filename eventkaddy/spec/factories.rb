FactoryBot.define do

  factory :user do
    email { "test@gmail.com" }
    first_name { "testing" }
    last_name { "test" }
    password { "Mfsi@0605#?#" }
  end

  factory :organization do
    name { "Blue Health Intelligence" }
  end

  factory :event do
    name { "Registration" }
    description { "Test site for BHI registration" }
    association :organization
  end

  factory :product_category do
    iid { "exhibitor_user_booth" }
    name { "Exhibitor User Booth" }
    association :event
  end

  factory :product do
    name { "Test Product Name" }
    iid { "test_product_name" }
    event { event }
    has_sizes { false }
    gl_code { "993hsjs" }
    price { 2000 }
    member_price { 1000 }
    quantity { 100 }
    start_date { Date.today }
    end_date { Date.today + 7 }
  end

  factory :exhibitor do
    event { event }
    company_name { "Mindfire" }
    email { "mfsi.venkatb+2134@gmail.com" }
    token { "test" }
  end

  factory :cart do
    status { "on_product_select_page" }
    association :user
  end

  factory :cart_item do
    quantity { 1 }
    association :cart
  end

  # qr_code
  # exhibitor_product
  # event_file
  factory :survey_type do
    name { 'Survey' }
  end

  factory :survey do
    association :survey_type
    association :event
    title { "Mindfire Survey" }
    description { "New Testing" }
  end

  factory :survey_section do
    association :event
    association :survey
  end

  factory :question_type do
    name { 'Question Type' }
  end

  factory :question do
    association :event
    association :survey
    association :survey_section
    association :question_type
  end

  factory :answer do
    association :event
    association :question
  end

  factory :hint do
    association :event
    association :question
  end

end
