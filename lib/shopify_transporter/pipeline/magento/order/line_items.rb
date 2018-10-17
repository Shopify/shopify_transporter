# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'
require 'pry'

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

          def remove_children(products)
            products.group_by { |product| product['sku'] }.map do |_sku, related_products|
              parent_with_child_name(related_products)
            end
          end

          def parent_with_child_name(related_products)
            child = related_products.find { |product| simple?(product) }
            parent = related_products.find { |product| configurable?(product) }
            return child if parent.nil?
            parent.merge('name' => child['name'])
          end

          def simple?(sub_product)
            sub_product['product_type'] == 'simple'
          end

          def configurable?(sub_product)
            sub_product['product_type'] == 'configurable'
          end

          def line_items(input)
            x = input.dig("items", "result", "items", "item")
            input["items"]["result"]["items"]["item"] = x.is_a?(Array) ? remove_children(x) : x
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
            return {} if item.nil?
            {
              quantity: item['qty_ordered'],
              sku: item['sku'],
              name: item['name'],
              total_discount: total_discount(item),
              requires_shipping: requires_shipping?(item),
              price: item['price'],
              taxable: taxable?(item),
              fulfillment_status: fulfillment_status(item),
              tax_lines: tax_lines(item),
              fulfillable_quantity: fulfillable_quantity(item),
            }.stringify_keys
          end

          def tax_lines(item)
            return unless tax_applied?(item)
            [
              {
                title: 'Tax',
                price: item['tax_amount'],
                rate: item['tax_percent'],
              }.stringify_keys,
            ]
          end

          def total_discount(item)
            item['discount_amount'] if item['discount_amount'].present? && item['discount_amount'].to_f != 0
          end

          def fulfillment_status(item)
            qty_ordered = qty_by_status(item, 'ordered')
            qty_shipped = qty_by_status(item, 'shipped')
            qty_refunded = qty_by_status(item, 'refunded')
            if qty_ordered == qty_shipped && qty_refunded == 0
              'fulfilled'
            elsif qty_shipped > 0 && qty_shipped < qty_ordered
              'partial'
            end
          end

          def fulfillable_quantity(item)
            qty_ordered = qty_by_status(item, 'ordered')
            qty_shipped = qty_by_status(item, 'shipped')
            qty_refunded = qty_by_status(item, 'refunded')

            qty_ordered - [qty_shipped, qty_refunded].max
          end

          def requires_shipping?(item)
            item['is_virtual'].to_i == 0 ? true : false
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
