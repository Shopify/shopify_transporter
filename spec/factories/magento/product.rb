# frozen_string_literal: true

FactoryBot.define do
  factory :magento_product, class: Hash do
    skip_create

    sequence(:name) { |n| "Nike-issue-#{n}" }
    sequence(:description) { |n| "description-#{n}" }
    sequence(:url_key) { |n| "handle-#{n}" }
    sequence(:created_at) { |n| "created_at-#{n}" }
    sequence(:visibility) { '1' }

    trait :with_parent_id do
      sequence(:parent_id) { |n| n.to_s }
    end

    trait :with_no_label_image do
      images do
        [
          {
            'url': :src_value,
            'position': 1,
            'label': {
              '@xsi:type': 'xsd:string'
            }
          }
        ]
      end
    end

    trait :with_label_image do
      images do
        [
          {
            'url': :src_value2,
            'position': 2,
            'label': 'alt_text'
          }
        ]
      end
    end
    trait :with_singular_image do
      images do
        {
          "file": "/c/s/csv.png",
          "position": 1,
          "url": "https://magento-sandbox.myshopify.io/media/catalog/product/c/s/csv.png",
          "label": 'alt_text'
        }
      end
    end

    trait :with_product_tags do
      tags do
        [
          {
            "tag_id": "17",
            "name": "white",
            "@xsi:type": "ns1:catalogProductTagListEntity"
          },
          {
            "tag_id": "18",
            "name": "shirt",
            "@xsi:type": "ns1:catalogProductTagListEntity"
          }
        ]
      end
    end

    trait :with_singular_tag do
      tags do
        {
          "tag_id": "19",
          "name": "grey"
        }
      end
    end

    trait :with_product_options do
      option1_name 'Color'
      option2_name 'Size'
      option3_name 'Style'
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :published_magento_product, class: Hash do
    skip_create

    sequence(:name) { |n| "Nike-issue-#{n}" }
    sequence(:description) { |n| "description-#{n}" }
    sequence(:url_key) { |n| "handle-#{n}" }
    sequence(:created_at) { |n| "created_at-#{n}" }
    sequence(:updated_at) { |n| "updated_at-#{n}" }
    sequence(:visibility) { '2' }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :configurable_magento_product, class: Hash do
    skip_create

    sequence(:product_id) { '1' }
    sequence(:title) { 'French Cuff Cotton Twill Oxford' }
    sequence(:body_html) { 'French Cuff Cotton Twill Oxford' }
    sequence(:handle) { 'french-cuff-cotton-twill-oxford' }
    sequence(:created_at) { '2013-03-05T01:25:10-05:00' }
    sequence(:published_scope) { 'web' }

    trait :with_img do
      images do
        [
          {
            "position": "1",
            "src": "parent_img_position_1",
          },
          {
            "position": "2",
            "src": "parent_img_position_2",
          },
          {
            "position": "4",
            "src": "parent_img_position_4",
          }
        ]

      end
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :simple_magento_product, class: Hash do
    skip_create

    sequence(:product_id) { '2' }
    sequence(:title) { 'French Cuff Cotton Twill Oxford' }
    sequence(:body_html) { 'Button front. Long sleeves. Tapered collar, chest pocket, french cuffs.' }
    sequence(:handle) { 'french-cuff-cotton-twill-oxford' }
    sequence(:created_at) { '2013-03-05T01:25:10-05:00' }
    sequence(:published_scope) { 'web' }
    type 'simple'

    trait :with_parent_id do
      sequence(:parent_id) { |n| n.to_s }
    end

    trait :with_img do
      images do
        [
          {
            "file": "/m/s/msj000a_1.jpg",
            "position": "2",
            "url": "child_img_position_2",
          },
          {
            "file": "/m/s/msj000c_1.jpg",
            "position": "4",
            "url": "child_img_position_4",
          }
        ]
      end
    end

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :advanced_magento_configurable_product, class: Hash do
    skip_create

    sequence(:product_id) { '3' }
    sequence(:title) { 'French Cuff Cotton Twill Oxford' }
    sequence(:body_html) { 'French Cuff Cotton Twill Oxford' }
    sequence(:handle) { 'french-cuff-cotton-twill-oxford' }
    sequence(:variants) { [] }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :advanced_magento_simple_product, class: Hash do
    skip_create

    sequence(:product_id) { |n| n }
    sequence(:title) { 'French Cuff Cotton Twill Oxford' }
    sequence(:body_html) { 'Button front. Long sleeves. Tapered collar, chest pocket, french cuffs.' }
    sequence(:handle) { 'french-cuff-cotton-twill-oxford' }
    sequence(:inventory_quantity) { |n| n }
    sequence(:parent_id) { '3' }
    sequence(:price) { '222' }
    sequence(:weight) { '100' }
    sequence(:sku) { |n| "m#{n}" }
    type 'simple'

    trait :with_parent_id do
      sequence(:parent_id) { |n| n.to_s }
    end

    initialize_with { attributes.deep_stringify_keys }
  end
end
