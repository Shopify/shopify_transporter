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
    sequence(:order_currency_code) { 'CAD' }
    sequence(:total_qty_ordered) { "1.000" }
    sequence(:weight) { '40' }

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

    trait :with_qty_shipped do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= [create(:magento_order_shipped_qty)]
        order['items']
      end
    end

    trait :with_qty_shipped_singular do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= create(:magento_order_shipped_qty)
        order['items']
      end
    end

    trait :with_cancelled_status_history do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['status_history'] ||= {}
        order['items']['result']['status_history']['item'] ||= [create(:magento_cancelled_status_history)]
        order['items']
      end
    end

    trait :with_cancelled_status_history_singular do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['status_history'] ||= {}
        order['items']['result']['status_history']['item'] ||= create(:magento_cancelled_status_history)
        order['items']
      end
    end

    trait :with_closed_status_history do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['status_history'] ||= {}
        order['items']['result']['status_history']['item'] ||= [create(:magento_closed_status_history)]
        order['items']
      end
    end

    trait :with_fixed_amount_discount do
      after(:build) do |order, evaluator|
        order['discount_amount'] = '-15.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
      end
    end

    trait :with_shipping_discount do
      after(:build) do |order, evaluator|
        order['shipping_discount_amount'] = '15.00'
        order['shipping_amount'] = '10.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
      end
    end

    trait :with_shipping_info do
      after(:build) do |order, evaluator|
        order['shipping_description'] = 'FedEx - 2nd Day Air'
        order['shipping_amount'] = '25.00'
        order['shipping_method'] = 'FedEx'
        order['shipping_tax_amount'] = '10'
      end
    end

    trait :with_disqualified_shipping_discount do
      after(:build) do |order, evaluator|
        order['shipping_discount_amount'] = '15.00'
        order['shipping_amount'] = '100.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
      end
    end

    trait :with_percentage_discount do
      after(:build) do |order, evaluator|
        order['discount_amount'] = '-15.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= create(:magento_percentage_discount)
      end
    end

    trait :with_zero_percentage_discount do
      after(:build) do |order, evaluator|
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= create(:magento_zero_percentage_discount)
      end
    end

    trait :with_percentage_discounts do
      after(:build) do |order, evaluator|
        order['discount_amount'] = '-15.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= [
          create(:magento_percentage_discount),
          create(:magento_percentage_discount)
        ]
      end
    end

    trait :with_disqualified_percentage_discount do
      after(:build) do |order, evaluator|
        order['discount_amount'] = '-15.00'
        order['discount_description'] = 'TEST_DISCOUNT_CODE'
        order['items'] ||= {}
        order['items']['result'] ||= {}
        order['items']['result']['items'] ||= {}
        order['items']['result']['items']['item'] ||= [
          {
            discount_percent: '25.00'
          },
          {
            discount_percent: '10.00'
          }
        ]
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
    sequence(:company) {|n| "billing test company-#{n}"}

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
    sequence(:company) {|n| "shipping test company-#{n}"}

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
    product_type 'simple'

    initialize_with { attributes.stringify_keys }
  end

  factory :magento_order_shipped_qty, class: Hash do
    skip_create
    sequence(:qty_shipped) { "1.0000" }
    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_cancelled_status_history, class: Hash do
    skip_create
    sequence(:created_at) { "2013-06-18 18:09:08" }
    sequence(:status) { "canceled" }
    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_closed_status_history, class: Hash do
    skip_create
    sequence(:created_at) { "2014-06-18 18:09:08" }
    sequence(:status) { "closed" }
    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_percentage_discount, class: Hash do
    skip_create
    sequence(:discount_percent) { "25.00" }
    initialize_with { attributes.deep_stringify_keys }
  end

  factory :magento_zero_percentage_discount, class: Hash do
    skip_create
    sequence(:discount_percent) { "0.00" }
    initialize_with { attributes.deep_stringify_keys }
  end
end
