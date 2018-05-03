# frozen_string_literal: true

FactoryBot.define do
  factory :magento_order, class: Hash do
    skip_create

    sequence(:increment_id) { |n| "increment_id-#{n}" }
    sequence(:created_at) { |n| "created_at-#{n}" }
    sequence(:customer_email) { |n| "customer_email-#{n}" }
    sequence(:customer_firstname) { |n| "customer_firstname-#{n}" }
    sequence(:customer_lastname) { |n| "customer_lastname-#{n}" }
    sequence(:subtotal) { |n| "subtotal-#{n}" }
    sequence(:tax_amount) { |n| "tax_amount-#{n}" }
    sequence(:grand_total) { |n| "grand_total-#{n}" }

    trait :with_line_items do
      transient do
        line_item_count 1
        line_items nil
      end

      items do
        items = if line_items.present?
          line_items
        else
          create_list(:magento_order_line_item, line_item_count)
        end
        {
          result: {
            items: {
              item: items
            }
          }
        }
      end

      initialize_with { attributes.deep_stringify_keys }
    end

    trait :with_billing_address do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['billing_address'] = create(:magento_order_billing_address)
        order['items']
      end
    end

    trait :with_shipping_address do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['shipping_address'] = create(:magento_order_shipping_address)
        order['items']
      end
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_order_billing_address, class: Hash do
    skip_create


    sequence(:firstname) { |n| "billing test first name-#{n}" }
    sequence(:lastname) { |n| "billing test last name-#{n}" }
    sequence(:telephone) { |n| "billing test telephone-#{n}" }
    sequence(:street) { |n| "billing test street-#{n}" }
    sequence(:city) { |n| "billing test city-#{n}" }
    sequence(:region) { |n| "billing test region-#{n}" }
    sequence(:postcode) { |n| "billing test postcode-#{n}" }
    sequence(:country_id) { |n| "billing test country-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_order_shipping_address, class: Hash do
    skip_create

    sequence(:firstname) { |n| "shipping test first name-#{n}" }
    sequence(:lastname) { |n| "shipping test last name-#{n}" }
    sequence(:telephone) { |n| "shipping test telephone-#{n}" }
    sequence(:street) { |n| "shipping test street-#{n}" }
    sequence(:city) { |n| "shipping test city-#{n}" }
    sequence(:region) { |n| "shipping test region-#{n}" }
    sequence(:postcode) { |n| "shipping test postcode-#{n}" }
    sequence(:country_id) { |n| "shipping test country-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_order_line_item, class: Hash do
    skip_create

    sequence(:qty_ordered) { |n| "qty_ordered-#{n}" }
    sequence(:sku) { |n| "sku-#{n}" }
    sequence(:name) { |n| "name-#{n}" }
    sequence(:price) { |n| "price-#{n}" }
    sequence(:tax_amount) { |n| "tax_amount-#{n}" }
    sequence(:tax_percent) { |n| "tax_percent-#{n}" }

    initialize_with { attributes.stringify_keys }
  end
end
