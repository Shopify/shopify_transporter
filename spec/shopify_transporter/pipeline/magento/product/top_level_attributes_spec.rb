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
          published_at: '',
          published_scope: '',
        }

        expect(shopify_product).to eq(expected_shopify_product.deep_stringify_keys)
      end

      it 'should handle published scope properly' do
        magento_product = FactoryBot.build(:published_magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product = {
          title: magento_product['name'],
          body_html: magento_product['description'],
          handle: magento_product['url_key'],
          published: true,
          published_at: magento_product['updated_at'],
          published_scope: "global",
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
          title: magento_product['name'],
          body_html: magento_product['description'],
          handle: magento_product['url_key'],
          published_scope: '',
          published: false,
          published_at: ''
        }
        expect(shopify_product).to eq(expected_shopify_product.deep_stringify_keys)
      end
    end
  end
end
