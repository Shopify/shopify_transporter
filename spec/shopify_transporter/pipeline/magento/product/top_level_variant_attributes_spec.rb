# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_variant_attributes'
require 'pry'
module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelVariantAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level product variant attributes from an input hash' do
        child_product = FactoryBot.build(:advanced_simple_product)
        parent_product = FactoryBot.build(:advanced_configurable_product, {variants: [child_product]})
        variants_in_shopify_format = described_class.new.convert(child_product, parent_product)
        expected_variants_in_shopify_format = [
            {
              sku: 'm100',
              grams: '100',
              price: '222'
            }.deep_stringify_keys
          ]
        expect(expected_variants_in_shopify_format).to eq(variants_in_shopify_format)
      end

      it 'ignores attributes that are not explicitly specified in the top-level' do
        with_nonsense = {
          nonsense_value: :blah,
          nonsense_key: :foo,
          nonsense_namespace: :bar,
        }
        child_product = FactoryBot.build(:advanced_simple_product, with_nonsense)
        parent_product = FactoryBot.build(:advanced_configurable_product, {variants: [child_product]})
        variants_in_shopify_format = described_class.new.convert(child_product, parent_product)
        expected_variants_in_shopify_format = [
          {
            sku: 'm100',
            grams: '100',
            price: '222'
          }.deep_stringify_keys
        ]
        expect(expected_variants_in_shopify_format).to eq(variants_in_shopify_format)
      end
    end
  end
end
