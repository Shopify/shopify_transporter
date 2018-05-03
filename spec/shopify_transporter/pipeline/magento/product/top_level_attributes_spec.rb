# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level shopify product attributes from an input hash' do
        magento_product = FactoryBot.build(:magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product = {
          sku: magento_product['sku'],
          title: magento_product['name'],
          body_html: magento_product['description'],
        }

        expect(shopify_product).to eq(expected_shopify_product.deep_stringify_keys)
      end

      it 'ignores attributes that are not explicitly specified in the top-level' do
        with_nonsense = {
          nonsense_value: :blah,
          nonsense_key: :foo,
          nonsense_namespace: :bar,
        }
        magento_product = FactoryBot.build(:magento_product, with_nonsense)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product = {
          sku: magento_product['sku'],
          title: magento_product['name'],
          body_html: magento_product['description'],
        }

        expect(shopify_product).to eq(expected_shopify_product.deep_stringify_keys)
      end
    end
  end
end
