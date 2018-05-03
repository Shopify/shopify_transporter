# frozen_string_literal: true

FactoryBot.define do
  factory :shopify_customer_hash, class: Hash do
    skip_create

    sequence(:email) { |n| "john-doe-#{n}@test.com" }
    sequence(:phone) { |n| format("519%07d", n) }
    sequence(:first_name) { |n| "John-#{n}" }
    sequence(:last_name) { |n| "Doe-#{n}" }
    sequence(:company) { |n| "Acme-Co-#{n}" }
    accepts_marketing 'false'
    sequence(:tags) { |n| "Tag-#{n}" }
    sequence(:note) { |n| "Note-#{n}" }
    tax_exempt 'false'
    send_email_invite 'false'
    send_email_welcome 'false'

    trait :with_metafields do
      transient do
        metafields nil
        metafield_count 1
      end

      after(:build) do  |customer, evaluator|
        customer['metafields'] = evaluator.metafields || create_list(:metafield, evaluator.metafield_count) 
      end
    end

    trait :with_addresses do
      transient do
        addresses nil
        address_count 1
      end

      after(:build) do  |customer, evaluator|
        customer['addresses'] = evaluator.addresses || create_list(:address, evaluator.address_count) 
      end
    end
    initialize_with { attributes.deep_stringify_keys }
  end
end
