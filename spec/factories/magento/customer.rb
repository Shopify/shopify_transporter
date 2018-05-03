# frozen_string_literal: true

FactoryBot.define do
  factory :magento_customer, class: Hash do
    skip_create

    sequence(:customer_id) { |n| "customer-id-#{n}" }
    sequence(:created_at) { |n| "created-at-#{n}" }
    sequence(:updated_at) { |n| "updated-at-#{n}" }
    sequence(:store_id) { |n| "store-id-#{n}" }
    sequence(:website_id) { |n| "website-id-#{n}" }
    sequence(:created_id) { |n| "created-in-#{n}" }
    sequence(:email) { |n| "email-#{n}" }
    sequence(:firstname) { |n| "firstname-#{n}" }
    sequence(:lastname) { |n| "lastname-#{n}" }
    sequence(:group_id) { |n| "group-id-#{n}" }


    trait :with_addresses do
      transient do
        address_count 1
        addresses nil
      end
      
      address_list do
        list = if addresses.present?
          addresses 
        else
          create_list(:magento_address, address_count)
        end
        {
          customer_address_list_response: {
            result: {
              item: list.size == 1 ? list.first : list
            }
          }
        }
      end

      initialize_with { attributes.deep_stringify_keys }
    end

    with_addresses

    initialize_with { attributes.deep_stringify_keys }
  end
end
