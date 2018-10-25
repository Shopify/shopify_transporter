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
            combine_associated_line_items(line_items.map { |item| line_item(item) })
          end

          def combine_associated_line_items(line_items)
            line_items.group_by { |line_item| line_item['sku'] }.map do |sku, associated_items|
              case associated_items.size
              when 1
                associated_items.first
              when 2
                parent = associated_items.find { |x| x['product_type'] == 'configurable' }
                child = associated_items.find { |x| x['product_type'] == 'simple' }
                parent.merge(child.slice('name'))
              end.except('product_type')
            end
          end

          def line_items_array(input)
            item = input.dig('items', 'result', 'items', 'item')
            return [] unless item
            item.is_a?(Array) ? item : [item]
          end

          def line_item(item)
            {
              quantity: item['qty_ordered'],
              sku: item['sku'],
              name: item['name'],
              requires_shipping: requires_shipping?(item),
              price: item['price'],
              taxable: taxable?(item),
              fulfillment_status: fulfillment_status(item),
              tax_lines: tax_lines(item),
              product_type: item['product_type'],
            }.stringify_keys
          end

          def tax_lines(item)
            return unless tax_applied?(item)
            [
              {
                title: 'Tax',
                price: item['tax_amount'],
                rate: tax_percentage(item),
              }.stringify_keys,
            ]
          end

          def tax_percentage(item)
            item['tax_percent'].to_f / 100
          end

          def fulfillment_status(item)
            qty_ordered = qty_by_status(item, 'ordered')
            qty_shipped = qty_by_status(item, 'shipped')
            qty_refunded = qty_by_status(item, 'refunded')
            if fully_fulfilled?(qty_ordered, qty_shipped, qty_refunded)
              'fulfilled'
            elsif partially_fulfilled?(qty_shipped, qty_ordered)
              'partial'
            end
          end

          def fully_fulfilled?(qty_ordered, qty_shipped, qty_refunded)
            qty_ordered == qty_shipped && qty_refunded == 0 && qty_shipped > 0
          end

          def partially_fulfilled?(qty_shipped, qty_ordered)
            qty_shipped > 0 && qty_shipped < qty_ordered
          end

          def requires_shipping?(item)
            item['is_virtual'].to_i == 0
          end

          def taxable?(item)
            item['tax_amount'].to_f > 0
          end

          def qty_by_status(item, status)
            key = "qty_#{status}"
            item[key].present? ? item[key].to_i : 0
          end

          def tax_applied?(item)
            item['tax_percent'].to_f > 0 && item['tax_amount'].to_f > 0
          end
        end
      end
    end
  end
end
