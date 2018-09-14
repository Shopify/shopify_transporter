# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class LineItems < Pipeline::Stage
          def convert(input, record)
            record.merge!(
              {
                line_items: line_items(input),
              }.stringify_keys
            )
          end

          private

          def line_items(input)
            line_items = line_items_array(input)
            line_items.map { |item| line_item(item) }
          end

          def line_items_array(input)
            items_1 = input['items']
            result = items_1 && items_1['result']
            items_2 = result && result['items']
            item = items_2 && items_2['item']
            return [] unless item
            item.is_a?(Array) ? item : [item]
          end

          def line_item(item)
            {
              quantity: item['qty_ordered'],
              sku: item['sku'],
              name: item['name'],
              price: item['price'],
              tax_lines: tax_lines(item),
            }.stringify_keys
          end

          def tax_lines(item)
            # Magento supports only one type of tax, the tax_lines should always be in array format
            [{
              title: 'Tax',
              price: item['tax_amount'],
              rate: item['tax_percent'],
            }.stringify_keys]
          end
        end
      end
    end
  end
end
