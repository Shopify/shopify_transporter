FactoryBot.define do
  factory :shopify_order_hash, class: Hash do
    skip_create

    sequence(:name) { |n| "name-#{n}" }
    sequence(:email) { |n| "email-#{n}" }
    sequence(:financial_status) { |n| "financial-status-#{n}" }
    sequence(:fulfillment_status) { |n| "fulfillment-status-#{n}" }
    sequence(:currency) { |n| "currency-#{n}" }
    sequence(:buyer_accepts_marketing) { |n| "buyer-accepts-marketing-#{n}" }
    sequence(:cancel_reason) { |n| "cancel-reason-#{n}" }
    sequence(:cancelled_at) { |n| "cancelled-at-#{n}" }
    sequence(:closed_at) { |n| "closed-at-#{n}" }
    sequence(:tags) { |n| "tags-#{n}" }
    sequence(:note) { |n| "note-#{n}" }
    sequence(:phone) { |n| "phone-#{n}" }
    sequence(:referring_site) { |n| "referring-site#{n}" }
    sequence(:processed_at) { |n| "processed-at-#{n}" }
    sequence(:source_name) { |n| "source-name-#{n}" }
    sequence(:total_discounts) { |n| "total-discounts#{n}" }
    sequence(:total_weight) { |n| "total-weight-#{n}" }
    sequence(:total_tax) { |n| "total-tax-#{n}" }

    trait :with_line_items do
      transient do
        line_item_count 1
        tax_line_count 1 
      end

      line_items do
        if tax_line_count > 0
          create_list(:order_line_item, line_item_count, :with_tax_lines, tax_line_count: tax_line_count)
        else
          create_list(:order_line_item, line_item_count)
        end
      end
    end

    trait :with_shipping_address do
      association :shipping_address, factory: :address
      initialize_with do
        attributes.stringify_keys
      end
    end

    trait :with_billing_address do
      association :billing_address, factory: :address
      initialize_with do
        attributes.stringify_keys
      end
    end

    trait :with_metafields do
      transient do
        metafields nil
        metafield_count 1
      end

      after(:build) do  |order, evaluator|
        order['metafields'] = evaluator.metafields || create_list(:metafield, evaluator.metafield_count)
      end
    end

    trait :complete do
      transient do
        tax_line_count 0
      end

      with_line_items
      with_shipping_address
      with_billing_address
      with_metafields
    end

    initialize_with { attributes.stringify_keys }
  end

  factory :order_line_item, class: Hash do
    skip_create

    sequence(:name) { |n| "name-#{n}" }
    sequence(:quantity) { |n| "quantity-#{n}" }
    sequence(:price) { |n| "price-#{n}" }
    sequence(:compare_at_price) { |n| "compare-at-price-#{n}" }
    sequence(:taxable) { |n| "taxable-#{n}" }
    sequence(:requires_shipping) { |n| "requires-shipping#{n}" }
    sequence(:sku) { |n| "sku-#{n}" }
    sequence(:fulfillment_status) { |n| "fulfillment-status#{n}" }
    sequence(:discount) { |n| "discount-#{n}" }

    trait :with_tax_lines do
      transient do
        tax_line_count = 1
      end

      tax_lines do
        create_list(:line_item_tax_line, tax_line_count)
      end
    end

    initialize_with { attributes.stringify_keys }
  end

  factory :line_item_tax_line, class: Hash do
    skip_create

    sequence(:title) { |n| "title-#{n}" }
    sequence(:price) { |n| "price-#{n}" }
    sequence(:rate) { |n| "rate-#{n}" }

    initialize_with { attributes.stringify_keys }
  end
end
