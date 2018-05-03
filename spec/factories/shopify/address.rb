FactoryBot.define do
  factory :address, class: Hash do
    skip_create

    sequence(:first_name) { |n| "first-name-#{n}" }
    sequence(:last_name) { |n| "last-name-#{n}" }
    sequence(:phone) { |n| "phone-#{n}" }
    sequence(:address1) { |n| "address1-#{n}" }
    sequence(:address2) { |n| "address2-#{n}" }
    sequence(:city) { |n| "city-#{n}" }
    sequence(:province) { |n| "province-#{n}" }
    sequence(:province_code) { |n| "province code-#{n}" }
    sequence(:country) { |n| "country-#{n}" }
    sequence(:country_code) { |n| "country code-#{n}" }
    sequence(:zip) { |n| "zip-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end
end
