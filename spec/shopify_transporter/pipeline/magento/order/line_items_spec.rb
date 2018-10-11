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

      it 'extracts line item attributes from an input hash' do
        magento_order_line_items = 2.times.map do |i|
          FactoryBot.build(:magento_order_line_item,
            qty_ordered: "qty ordered #{i}",
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_amount: "10",
            tax_percent: "12",
          )
        end
        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_items)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order_line_items = 2.times.map do |i|
          {
            quantity: "qty ordered #{i}",
            sku: "sku #{i}",
            name: "name #{i}",
            price: "price #{i}",
            tax_lines: [
              {
                title: 'Tax',
                price: "10",
                rate: "12",
              }
            ]
          }.deep_stringify_keys
        end
        expect(shopify_order['line_items']).to match_array(expected_shopify_order_line_items)
      end

      it 'should not generate tax info for a line item if zero tax is applied' do
        magento_order_line_item = [
          FactoryBot.build(:magento_order_line_item,
            qty_ordered: "qty ordered",
            sku: "sku",
            name: "name",
            price: "price",
            tax_amount: "0",
            tax_percent: "0",
          )
        ]

        magento_order = FactoryBot.build(:magento_order, :with_line_items, line_items: magento_order_line_item)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order_line_item = [
          {
            quantity: "qty ordered",
            sku: "sku",
            name: "name",
            price: "price",
            tax_lines: nil
          }.deep_stringify_keys
        ]
        expect(shopify_order['line_items']).to match_array(expected_shopify_order_line_item)
      end

    end
  end
end
