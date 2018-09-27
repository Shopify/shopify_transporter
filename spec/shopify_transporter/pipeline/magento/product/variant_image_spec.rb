# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/variant_image'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe VariantImage, type: :helper do
    context '#convert' do
      it 'should extract the correct image as the variant image and add that to the parent image list' do
        simple_product_with_img = FactoryBot.build(:simple_magento_product, :with_img)
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

      it 'should skip variant image conversion if the child product has no image attached' do
        simple_product_without_img = FactoryBot.build(:simple_magento_product)
        configurable_product_with_img = FactoryBot.build(:configurable_magento_product, :with_img, 'variants': [simple_product_without_img])
        should_skip_conversion = described_class.new.convert(simple_product_without_img, configurable_product_with_img).nil?
        expect(should_skip_conversion).to be true
      end

      it 'should skip variant image conversion if the input product is not a child product' do
        magento_product = FactoryBot.build(:magento_product)
        configurable_product_with_img = FactoryBot.build(:configurable_magento_product, :with_img, 'variants': [magento_product])
        should_skip_conversion = described_class.new.convert(magento_product, configurable_product_with_img).nil?
        expect(should_skip_conversion).to be true
      end
    end
  end
end
