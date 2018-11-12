# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_variant_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelVariantAttributes, type: :helper do
    context '#convert' do
      it 'does not accumulate anything if product is not a simple product' do
        magento_product = FactoryBot.build(:configurable_magento_product)
        shopify_product = {}

        described_class.new.convert(magento_product, shopify_product)

        expect(shopify_product).to eq({})
      end

      it 'extracts top level product variant attributes from an input hash' do
        child_product = FactoryBot.build(:advanced_magento_simple_product, :with_parent_id)
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

      context 'special_price conversions' do
        it 'sets shopify price to match magento price when special_price is not present' do
          child_product = FactoryBot.build(:advanced_magento_simple_product, :with_parent_id, price: '15')
          parent_product = FactoryBot.build(:advanced_magento_configurable_product,
            variants: [
              {
                'product_id': child_product['product_id'],
              },
            ])

          described_class.new.convert(child_product, parent_product)

          expected_variant_information = {
            price: child_product['price'],
          }

          expect(parent_product['variants'].first).to include(expected_variant_information.deep_stringify_keys)
        end

        it 'sets shopify price to match the magento special_price when it is present' do
          child_product = FactoryBot.build(:advanced_magento_simple_product, :with_parent_id, price: '15', special_price: '10')
          parent_product = FactoryBot.build(:advanced_magento_configurable_product,
            variants: [
              {
                'product_id': child_product['product_id'],
              },
            ])

          described_class.new.convert(child_product, parent_product)

          expected_variant_information = {
            price: child_product['special_price'],
            compare_at_price: child_product['price'],
          }

          expect(parent_product['variants'].first).to include(expected_variant_information.deep_stringify_keys)
        end
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
        child_product = FactoryBot.build(:advanced_magento_simple_product, :with_parent_id)
        another_child_product = FactoryBot.build(:advanced_magento_simple_product, :with_parent_id)
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

      it 'should skip converting top level variants when the input is a configurable product' do
        configurable_product = FactoryBot.build(:configurable_magento_product)
        parent_product = {}

        described_class.new.convert(configurable_product, parent_product)

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
          'type' => 'simple',
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
          'type' => 'simple',
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
