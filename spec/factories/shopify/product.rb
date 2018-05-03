# frozen_string_literal: true

FactoryBot.define do
  factory :shopify_product, class: Hash do
    skip_create

    sequence(:handle) { |n| "Handle-#{n}" }
    sequence(:title) { |n| "Title-#{n}" }
    sequence(:body_html) { |n| "Body (HTML)-#{n}" }
    sequence(:tags) { |n| "Tags-#{n}" }
    sequence(:vendor) { |n| "Vendor-#{n}" }
    sequence(:published) { |n| "Published-#{n}" }
    sequence(:published_at) { |n| "Published At-#{n}" }
    sequence(:published_scope) { |n| "Published Scope-#{n}" }
    sequence(:template_suffix) { |n| "Template Suffix-#{n}" }
    sequence(:metafields_global_title_tag) { |n| "Metafields Global Title Tag-#{n}" }
    sequence(:metafields_global_description_tag) { |n| "Metafields Global Description Tag-#{n}" }
    sequence(:product_type) { |n| "Type-#{n}" }

    trait :with_metafields do
      transient do
        metafield_count 1
      end

      metafields do
        create_list(:metafield, metafield_count)
      end
    end

    trait :with_variants do
      transient do
        variant_count 1
        variant_metafield_count 0
      end

      variants do
        if variant_metafield_count > 0
          create_list(
            :shopify_product_variant,
            variant_count,
            :with_metafields,
            metafield_count: variant_metafield_count
          )
        else
          create_list(:shopify_product_variant, variant_count)
        end
      end
    end

    trait :with_images do
      transient do
        image_count 1
      end

      images do
        create_list(:shopify_product_image, image_count)
      end
    end

    options do
      [
        {
          'name': "Option 1 Name",
        },
        {
          'name': "Option 2 Name",
        },
        {
          'name': "Option 3 Name",
        },
      ]
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :shopify_product_variant, class: Hash do
    skip_create

    sequence(:option1) { |n| "option1 value-#{n}" }
    sequence(:option2) { |n| "option2 value-#{n}" }
    sequence(:option3) { |n| "option3 value-#{n}" }
    sequence(:sku) { |n| "variant sku-#{n}" }
    sequence(:grams) { |n| "variant grams-#{n}" }
    sequence(:inventory_qty) { |n| "variant inventory qty-#{n}" }
    sequence(:inventory_policy) { |n| "variant inventory policy-#{n}" }
    sequence(:fulfillment_service) { |n| "variant fulfillment service-#{n}" }
    sequence(:inventory_management) { |n| "variant inventory management-#{n}" }
    sequence(:price) { |n| "variant price-#{n}" }
    sequence(:compare_at_price) { |n| "variant compare at price-#{n}" }
    sequence(:requires_shipping) { |n| "variant requires shipping-#{n}" }
    sequence(:taxable) { |n| "variant taxable-#{n}" }
    sequence(:weight_unit) { |n| "variant weight unit-#{n}" }
    sequence(:variant_image) do |n|
      {
        src: "variant_image_src-#{n}"
      }
    end

    trait :with_metafields do
      transient do
        metafield_count 1
      end

      metafields do
        create_list(:metafield, metafield_count)
      end
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :shopify_product_image, class: Hash do
    skip_create

    sequence(:attachment) { |n| "attachment-#{n}" }
    sequence(:src) { |n| "src-#{n}" }
    sequence(:position) { |n| "position-#{n}" }
    sequence(:alt) { |n| "alt-#{n}" }

    initialize_with { attributes.deep_stringify_keys }
  end
end
