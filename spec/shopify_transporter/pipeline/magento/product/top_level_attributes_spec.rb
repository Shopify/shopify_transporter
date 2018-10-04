# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level shopify product attributes from an input hash' do
        magento_product = FactoryBot.build(:magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product = {
          title: magento_product['name'],
          body_html: magento_product['description'],
          handle: magento_product['url_key'],
          published: false,
          published_scope: '',
        }

        expect(shopify_product.deep_stringify_keys).to eq(expected_shopify_product.deep_stringify_keys)
      end

      it 'should handle published scope properly' do
        magento_product = FactoryBot.build(:published_magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product_published_scope = {
          published: true,
          published_at: magento_product['updated_at'],
          published_scope: "global",
        }

        expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_published_scope.deep_stringify_keys)
      end

      it 'ignores attributes that are not explicitly specified in the top-level' do
        with_nonsense = {
          nonsense_value: :blah,
          nonsense_key: :foo,
          nonsense_namespace: :bar,
        }
        magento_product = FactoryBot.build(:magento_product, with_nonsense)
        shopify_product = described_class.new.convert(magento_product, {})
        expect(shopify_product.deep_stringify_keys).to_not include(with_nonsense.deep_stringify_keys)
      end

      it 'should handle product tags conversion' do
        magento_product = FactoryBot.build(:magento_product, :with_product_tags)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_product_tag_info = {
          tags: 'white, shirt'
        }
        expect(shopify_product.deep_stringify_keys).to include(expected_product_tag_info.deep_stringify_keys)
      end

      it 'should handle product with only one tag' do
        magento_product = FactoryBot.build(:magento_product, :with_singular_tag)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_product_tag_info = {
          tags: 'grey'
        }
        expect(shopify_product.deep_stringify_keys).to include(expected_product_tag_info.deep_stringify_keys)
      end

      describe 'product options' do
        it 'extracts product options when there are three options' do
          magento_product = FactoryBot.build(:magento_product, :with_product_options)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_option_data = {
            options: [
              {
                'name': 'Color',
              },
              {
                'name': 'Size',
              },
              {
                'name': 'Style',
              },
            ],
          }
          expect(shopify_product.deep_stringify_keys).to include(expected_option_data.deep_stringify_keys)
        end

        it 'extracts product options when there are less than three options' do
          magento_product = FactoryBot.build(:magento_product)
          magento_product['option1_name'] = 'Color'
          shopify_product = described_class.new.convert(magento_product, {})
          expected_option_data = {
            options: [
              {
                'name': 'Color',
              },
              {
                'name': nil,
              },
              {
                'name': nil,
              },
            ],
          }
          expect(shopify_product.deep_stringify_keys).to include(expected_option_data.deep_stringify_keys)
        end

        it 'ignores the rest of options when there are more than three options' do
          magento_product = FactoryBot.build(:magento_product)
          magento_product['option1_name'] = 'option1'
          magento_product['option2_name'] = 'option2'
          magento_product['option3_name'] = 'option3'
          magento_product['option4_name'] = 'option4'
          shopify_product = described_class.new.convert(magento_product, {})
          expected_option_data =
            [
              {
                'name' => 'option1',
              },
              {
                'name' => 'option2',
              },
              {
                'name' => 'option3',
              }
            ]

          expect(shopify_product['options']).to eq(expected_option_data)
        end

        it 'does not extract product options when there are no options' do
          magento_product = FactoryBot.build(:magento_product)
          shopify_product = described_class.new.convert(magento_product, {})

          expect(shopify_product.keys).not_to include('options')
        end
      end



      context '#images' do
        it 'handles images with no labels' do
          magento_product = FactoryBot.build(:magento_product, :with_no_label_image)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_shopify_product_image = {
            images: [
              {
                src: :src_value,
                position: 1,
              }
            ]
          }

          expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_image.deep_stringify_keys)
        end

        it 'handles images with labels' do
          magento_product = FactoryBot.build(:magento_product, :with_label_image)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_shopify_product_image = {
            images: [
              {
                src: :src_value2,
                position: 2,
                alt: 'alt_text',
              }
            ]
          }

          expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_image.deep_stringify_keys)
        end

        it 'should handle product with only one image' do
          magento_product = FactoryBot.build(:magento_product, :with_singular_image)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_shopify_product_image =
            [
              {
                src: 'https://magento-sandbox.myshopify.io/media/catalog/product/c/s/csv.png',
                position: 1,
                alt: 'alt_text',
              }.deep_stringify_keys
            ]

          expect(shopify_product['images']).to eq(expected_shopify_product_image)
        end

        it 'Merge the parent image with the existing image arrays if child products get processed before parent product does' do
          record = {
            'images' => [
              {
                'src' => 'example_child_image_1'
              },
              {
                'src' => 'example_child_image_2'
              }
            ]
          }
          parent_product = FactoryBot.build(:configurable_magento_product, 'images' => [
            {
              'position' => '1',
              'url' => 'parent_img_position_1',
            },
            {
              'position' => '2',
              'url' => 'parent_img_position_2',
            },
            {
              'position' => '4',
              'url'=> 'parent_img_position_4',
            }
          ])
          shopify_product = described_class.new.convert(parent_product, record)

          expected_image_response = [
            {
              'src' => 'example_child_image_1'
            },
            {
              'src' => 'example_child_image_2'
            },
            {
              'position' => '1',
              'src' => 'parent_img_position_1',
            },
            {
              'position'=> '2',
              'src' => 'parent_img_position_2',
            },
            {
              'position' => '4',
              'src' => 'parent_img_position_4',
            }
          ]
          expect(shopify_product['images']).to eq (expected_image_response)

        end
      end
    end
  end
end
