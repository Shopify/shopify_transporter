FactoryBot.define do
  factory :metafield, class: Hash do
    skip_create
    sequence(:namespace) { |n| "namespace-#{n}" }
    sequence(:key) { |n| "key-#{n}" }
    sequence(:value) { |n| "value-#{n}" }
    sequence(:value_type) { |n| "value type-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end
end
