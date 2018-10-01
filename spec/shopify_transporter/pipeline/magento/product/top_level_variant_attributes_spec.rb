# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_variant_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelVariantAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level product variant attributes from an input hash' do
        child_product = FactoryBot.build(:advanced_magento_simple_product)
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': child_product['product_id'],
            },
          ])

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
              sku: child_product['sku'],
              weight: child_product['weight'],
              price: child_product['price'],
              inventory_qty: child_product['inventory_quantity'],
            }
          ]
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end

      it 'ignores attributes that are not explicitly specified in the top-level' do
        with_nonsense = {
          nonsense_value: :blah,
          nonsense_key: :foo,
          nonsense_namespace: :bar,
        }
        child_product = FactoryBot.build(:advanced_magento_simple_product, with_nonsense)
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': child_product['product_id'],
            },
          ])

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
              sku: child_product['sku'],
              weight: child_product['weight'],
              price: child_product['price'],
              inventory_qty: child_product['inventory_quantity'],
            }
          ]
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end

      it 'make sure the correct product is being converted when there exist multiple simple products as variants' do
        child_product = FactoryBot.build(:advanced_magento_simple_product)
        another_child_product = FactoryBot.build(:advanced_magento_simple_product)
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': child_product['product_id'],
            },
            {
              'product_id': another_child_product['product_id'],
            },
          ])

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
              sku: child_product['sku'],
              weight: child_product['weight'],
              price: child_product['price'],
              inventory_qty: child_product['inventory_quantity'],
            },
            {
              product_id: another_child_product['product_id'],
            },
          ],
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end

      it 'should skip converting top level variants when the input is a product without parent_id' do
        parent_product = {}
        simple_product_without_parent = FactoryBot.build(:simple_magento_product)
        simple_product_without_parent.delete('parent_id')
        described_class.new.convert(simple_product_without_parent, parent_product)
        expect(parent_product.keys).not_to include(:variants)
      end

      it 'extracts option information correctly when there are 3 options present' do
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': '111',
            },
          ])

        child_product = {
          'product_id' => '111',
          'parent_id' => parent_product['product_id'],
          'option1_name' => 'Color',
          'option1_value' => 'White',
          'option2_name' => 'Size',
          'option2_value' => 'XS',
          'option3_name' => 'Style',
          'option3_value' => 'T-Shirt',
        }

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
              option1: 'White',
              option2: 'XS',
              option3: 'T-Shirt',
            },
          ],
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end

      it 'extracts option information correctly when there is only 1 option present' do
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': '111',
            },
          ])

        child_product = {
          'product_id' => '111',
          'parent_id' => parent_product['product_id'],
          'option1_name' => 'Color',
          'option1_value' => 'White',
        }

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
              option1: 'White',
            },
          ],
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end

      it "does not extract option information if it isn't present" do
        parent_product = FactoryBot.build(:advanced_magento_configurable_product,
          variants: [
            {
              'product_id': '111',
            },
          ])

        child_product = {
          'product_id' => '111',
          'parent_id' => parent_product['product_id'],
        }

        described_class.new.convert(child_product, parent_product)

        expected_variant_information = {
          variants: [
            {
              product_id: child_product['product_id'],
            },
          ],
        }

        expect(parent_product).to include(expected_variant_information.deep_stringify_keys)
      end
    end
  end
end
