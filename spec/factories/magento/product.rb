# frozen_string_literal: true

FactoryBot.define do
  factory :magento_product, class: Hash do
    skip_create

    sequence(:sku) { |n| "#{n}" }
    sequence(:name) { |n| "Nike-issue-#{n}" }
    sequence(:description) { |n| "description-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end
end
