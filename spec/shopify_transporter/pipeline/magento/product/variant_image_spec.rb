# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/variant_image'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe VariantImage, type: :helper do
    context '#convert' do
      it 'should extract the correct image as the variant image and add that to the parent image list' do
        simple_product_with_img = FactoryBot.build(:simple_magento_product, :with_img, :with_parent_id)
        configurable_product_with_img = FactoryBot.build(:configurable_magento_product, :with_img, 'variants': [simple_product_with_img])
        shopify_product = described_class.new.convert(simple_product_with_img, configurable_product_with_img)
        expected_variant_image_info = {
          'variant_image' => {
            'src' => 'child_img_position_2'
          }
        }

        expected_parent_image_info = [
          {
            'position' => '1',
            'src' => 'parent_img_position_1'
          },
          {
            'position' => '2',
            'src' => 'parent_img_position_2'
          },
          {
            'position' => "4",
            'src' => 'parent_img_position_4'
          },
          {
            'src' => 'child_img_position_2'
          }
        ]

        expect(shopify_product['images']).to eq  expected_parent_image_info
        expect(shopify_product['variants'].first).to include  expected_variant_image_info
      end

      it 'should work when there are multiple child products with variant images' do
        simple_product_with_img = FactoryBot.build(:simple_magento_product, :with_img, :with_parent_id)
        another_simple_product_with_img = FactoryBot.build(:simple_magento_product, :with_parent_id, 'product_id': '3', 'images': [
          {
            "file": "child_img_position_1",
            "position": "1",
            "url": "child_img_position_1",
          },
          {
            "file": "child_img_position_5",
            "position": "5",
            "url": "child_img_position_5",
          }
        ])
        configurable_product = FactoryBot.build(:configurable_magento_product,'variants': [simple_product_with_img, another_simple_product_with_img])
        intermediate_record = described_class.new.convert(simple_product_with_img, configurable_product)
        shopify_product = described_class.new.convert(another_simple_product_with_img, intermediate_record)
        expected_variant_image_info = {
          'simple_product_with_img' => {
            'variant_image' => {
              'src' => 'child_img_position_2'
            }
          },
          'another_simple_product_with_img' => {
            'variant_image' => {
              'src' => 'child_img_position_1'
            }
          }
        }

        expected_parent_image_info = [
          {
            'src' => 'child_img_position_2'
          },
          {
            'src' => 'child_img_position_1'
          }
        ]

        expect(shopify_product['images']).to eq  expected_parent_image_info
        expect(shopify_product['variants'].first).to include  expected_variant_image_info['simple_product_with_img']
        expect(shopify_product['variants'].second).to include  expected_variant_image_info['another_simple_product_with_img']
      end

      it 'should skip variant image conversion if the child product has no image attached' do
        simple_product_without_img = FactoryBot.build(:simple_magento_product)
        configurable_product_with_img = FactoryBot.build(:configurable_magento_product, :with_img, 'variants': [simple_product_without_img])
        described_class.new.convert(simple_product_without_img, configurable_product_with_img)
        expect(configurable_product_with_img['variants'].first.key?('images'))
      end

      it 'should skip variant image conversion if the input product is a configurable product' do
        magento_product = FactoryBot.build(:magento_product)
        configurable_product_with_img = FactoryBot.build(:configurable_magento_product, :with_img, 'variants': [magento_product])
        described_class.new.convert(magento_product, configurable_product_with_img)
        expect(configurable_product_with_img['variants'].first.key?('images'))
      end

      it 'should skip variant image conversion if the input product does not have a parent product' do
        magento_product = FactoryBot.build(:magento_product)
        configurable_product_with_img = FactoryBot.build(:simple_magento_product, :with_img, 'variants': [magento_product])
        described_class.new.convert(magento_product, configurable_product_with_img)
        expect(configurable_product_with_img['variants'].first.key?('images'))
      end
    end
  end
end
