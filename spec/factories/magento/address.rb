FactoryBot.define do
  factory :magento_address, class: Hash do
    skip_create

    sequence(:firstname) { |n| "firstname-#{n}" }
    sequence(:lastname) { |n| "lastname-#{n}" }
    sequence(:street) { |n| "street-#{n}" }
    sequence(:city) { |n| "city-#{n}" }
    sequence(:region) { |n| "region-#{n}" }
    sequence(:country_id) { |n| "country-id-#{n}" }
    sequence(:postcode) { |n| "postcode-#{n}" }
    sequence(:company) { |n| "company-#{n}" }
    sequence(:telephone) { |n| "telephone-#{n}" }
    sequence(:is_default_shipping) { |n| "is-default-shipping-#{n}" }
    sequence(:is_default_billing) { |n| "is-default-billing-#{n}" }

    initialize_with { attributes.stringify_keys }
  end
end
