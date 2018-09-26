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
        expected_variants_in_shopify_format = {
          sku: child_product['sku'],
          grams: child_product['weight'],
          price: child_product['price'],
          inventory_qty: child_product['inventory_quantity'],
        }

        expect(variants_in_shopify_format).to include(expected_variants_in_shopify_format.deep_stringify_keys)
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
        expected_variants_in_shopify_format = {
          sku: child_product['sku'],
          grams: child_product['weight'],
          price: child_product['price'],
          inventory_qty: child_product['inventory_quantity'],
        }

        expect(variants_in_shopify_format).to include(expected_variants_in_shopify_format.deep_stringify_keys)
      end

      it 'make sure the correct product is being converted when there exist multiple simple products as variants' do
        child_product = FactoryBot.build(:advanced_simple_product)
        another_child_product = FactoryBot.build(:advanced_simple_product)
        parent_product = FactoryBot.build(:advanced_configurable_product, {variants: [child_product, another_child_product]})
        variants_in_shopify_format = described_class.new.convert(child_product, parent_product)
        expected_variants_in_shopify_format = {
          product_id: child_product['product_id'],
          sku: child_product['sku'],
          grams: child_product['weight'],
          price: child_product['price'],
          inventory_qty: child_product['inventory_quantity'],
        }

        expect(variants_in_shopify_format).to include(expected_variants_in_shopify_format.deep_stringify_keys)
      end

      it 'should skip converting top level variants when the input is a product without parent_id' do
        simple_product_without_parent = FactoryBot.build(:simple_magento_product)
        simple_product_without_parent.delete("parent_id")
        binding.pry
        variants_in_shopify_format = described_class.new.convert(simple_product_without_parent, {})
        expect(variants_in_shopify_format).to be_nil
      end
    end
  end
end
