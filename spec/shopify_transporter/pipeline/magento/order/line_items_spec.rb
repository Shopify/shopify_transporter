# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe LineItems, type: :helper do
    context '#convert' do
      it "does not fail if the items can't be found in the expected nested structure" do
        magento_order = FactoryBot.build(:magento_order)
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['line_items']).to be_empty

        magento_order['items'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['line_items']).to be_empty

        magento_order['items']['result'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['line_items']).to be_empty

        magento_order['items']['result']['items'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['line_items']).to be_empty
      end

      it 'combines parent and child info into one line item if they share a sku' do
        parent = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'configurable', name: 'parent_name')
        child = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'simple', name: 'child_name')
        parent['price'] = 10
        child['price'] = 0
        magento_order_line_items = [parent, child]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = {}

        described_class.new.convert(magento_order, shopify_order)

        parent_line_item_with_child_name = {
          "name"=>child['name'],
          "price"=>parent['price'],
          "quantity"=>parent['qty_ordered'],
          "sku"=>parent['sku'],
        }

        expect(shopify_order['line_items'].size).to eq(1)
        expect(shopify_order['line_items'].first).to include(parent_line_item_with_child_name)
      end

      it 'will not combine two products if they share the same sku but are of the same type' do
        parent = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'simple', name: 'parent_name')
        child = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'simple', name: 'child_name')
        parent['price'] = 10
        child['price'] = 10
        magento_order_line_items = [parent, child]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = {}
        described_class.new.convert(magento_order, shopify_order)

        processed_line_items = [
          {
            "name"=>parent['name'],
            "price"=>parent['price'],
            "quantity"=>parent['qty_ordered'],
            "sku"=>parent['sku'],
          },
          {
            "name"=>child['name'],
            "price"=>child['price'],
            "quantity"=>child['qty_ordered'],
            "sku"=>child['sku'],
          },
        ]
        expect(shopify_order['line_items'][0]).to include(processed_line_items[0])
        expect(shopify_order['line_items'][1]).to include(processed_line_items[1])
      end

      it 'will not combine two products if they share the same sku but child product has a price larger than 0' do
        parent = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'configurable', name: 'parent_name')
        child = FactoryBot.build(:magento_order_line_item, sku: 'test_sku', product_type: 'simple', name: 'child_name')
        parent['price'] = 10
        child['price'] = 5
        magento_order_line_items = [parent, child]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = {}

        described_class.new.convert(magento_order, shopify_order)

        processed_line_items = [
          {
            "name"=>parent['name'],
            "price"=>parent['price'],
            "quantity"=>parent['qty_ordered'],
            "sku"=>parent['sku'],
          },
          {
            "name"=>child['name'],
            "price"=>child['price'],
            "quantity"=>child['qty_ordered'],
            "sku"=>child['sku'],
          },
        ]
        expect(shopify_order['line_items'][0]).to include(processed_line_items[0])
        expect(shopify_order['line_items'][1]).to include(processed_line_items[1])
      end

      it 'should combine meaningful pair of line items while leaving the rest as it is' do
        parent_1 = FactoryBot.build(:magento_order_line_item, sku: 'test_sku_1', product_type: 'configurable', name: 'parent_1_name')
        child_1 = FactoryBot.build(:magento_order_line_item, sku: 'test_sku_1', product_type: 'simple', name: 'child_1_name')
        parent_1['price'] = 10
        child_1['price'] = 0
        parent_2 = FactoryBot.build(:magento_order_line_item, sku: 'test_sku_2', product_type: 'simple', name: 'parent_2_name')
        child_2 = FactoryBot.build(:magento_order_line_item, sku: 'test_sku_2', product_type: 'simple', name: 'child_2_name')
        parent_2['price'] = 15
        child_2['price'] = 10
        magento_order_line_items = [parent_1, child_1, parent_2, child_2]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = {}
        described_class.new.convert(magento_order, shopify_order)

        processed_line_items = [
          {
            "name"=>child_1['name'],
            "price"=>parent_1['price'],
            "quantity"=>parent_1['qty_ordered'],
            "sku"=>parent_1['sku'],
          },
          {
            "name"=>parent_2['name'],
            "price"=>parent_2['price'],
            "quantity"=>parent_2['qty_ordered'],
            "sku"=>parent_2['sku'],
          },
          {
            "name"=>child_2['name'],
            "price"=>child_2['price'],
            "quantity"=>child_2['qty_ordered'],
            "sku"=>child_2['sku'],
          },
        ]
        expect(shopify_order['line_items'][0]).to include(processed_line_items[0])
        expect(shopify_order['line_items'][1]).to include(processed_line_items[1])
        expect(shopify_order['line_items'][2]).to include(processed_line_items[2])
      end

      it 'extracts line item attributes from an input hash' do
        magento_order_line_items = 2.times.map do |i|
          FactoryBot.build(:magento_order_line_item,
            qty_ordered: "5",
            qty_shipped: "5",
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_amount: "10",
            tax_percent: "12",
            is_virtual: "0"
          )
        end
        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order_line_items = 2.times.map do |i|
          {
            quantity: '5',
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_lines: [
              {
                title: 'Tax',
                price: '10',
                rate: 0.12,
              }
            ],
            requires_shipping: true,
            fulfillment_status: 'fulfilled',
            taxable: true
          }.deep_stringify_keys
        end
        expect(shopify_order['line_items']).to eq(expected_shopify_order_line_items)
      end

      it 'sets fulfillment_status to nil if neither fulfilled nor partial fulfilled' do
        magento_order_line_items = 2.times.map do |i|
          FactoryBot.build(:magento_order_line_item,
            qty_ordered: "0",
            qty_shipped: "0",
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_amount: "10",
            tax_percent: "12",
            is_virtual: "0"
          )
        end
        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order_line_items = 2.times.map do |i|
          {
            quantity: '0',
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_lines: [
              {
                title: 'Tax',
                price: '10',
                rate: 0.12,
              }
            ],
            requires_shipping: true,
            fulfillment_status: nil,
            taxable: true
          }.deep_stringify_keys
        end
        expect(shopify_order['line_items']).to eq(expected_shopify_order_line_items)
      end

      it 'should not generate tax info for a line item if zero tax is applied' do
        magento_order_line_item = [
          FactoryBot.build(:magento_order_line_item,
            qty_ordered: '5',
            qty_shipped: '3',
            sku: 'sku',
            name: 'name',
            price: 'price',
            is_virtual: '0'
          )
        ]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_item)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order_line_item = [
          {
            quantity: '5',
            sku: 'sku',
            name: 'name',
            price: 'price',
            tax_lines: nil,
            requires_shipping: true,
            fulfillment_status: 'partial',
            taxable: false
          }.deep_stringify_keys
        ]
        expect(shopify_order['line_items']).to eq(expected_shopify_order_line_item)
      end

    end
  end
end
