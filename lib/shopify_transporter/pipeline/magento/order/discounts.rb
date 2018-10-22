# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class Discounts < Pipeline::Stage
          def convert(input, record)
            record.merge!(
              {
                discounts: discounts(input),
              }.stringify_keys
            )
          end

          private

          def discounts(hash)
            [
              shipping_discount(hash),
              fixed_amount_discount(hash),
              percentage_discount(hash),
            ].compact
          end

          def shipping_discount(hash)
            shipping_discount_amount = value_as_float(hash, 'shipping_discount_amount')
            shipping_amount = value_as_float(hash, 'shipping_amount')
            if shipping_discount_amount > shipping_amount
              {
                code: discount_code(hash),
                amount: shipping_discount_amount,
                type: 'shipping',
              }.stringify_keys
            end
          end

          def fixed_amount_discount(hash)
            discount_amount = discount_amount(hash)
            discount_percentage = discount_percentage(hash)
            if discount_amount > 0 && discount_percentage == 0
              {
                code: discount_code(hash),
                amount: discount_amount,
                type: 'fixed_amount',
              }.stringify_keys
            end
          end

          def percentage_discount(hash)
            discount_amount = discount_amount(hash)
            discount_percentage = discount_percentage(hash)

            if discount_amount > 0 && discount_percentage != 0
              {
                code: discount_code(hash),
                amount: discount_percentage,
                type: 'percentage',
              }.stringify_keys
            end
          end

          def discount_percentage(hash)
            return 0 unless hash.dig('items', 'result', 'items', 'item').present?

            if line_items(hash).is_a?(Hash)
              value_as_float(line_items(hash), 'discount_percent')
            else
              discounts = line_items(hash).map do |line_item|
                value_as_float(line_item, 'discount_percent')
              end.uniq
              discount_applied_on_all_line_items?(discounts) ? discounts.first : 0
            end
          end

          def discount_code(hash)
            hash['discount_description'].present? ? hash['discount_description'] : 'Magento'
          end

          def discount_amount(hash)
            hash['discount_amount'].present? ? hash['discount_amount'].to_f.abs : 0
          end

          def value_as_float(hash, key)
            hash[key].present? ? hash[key].to_f : 0
          end

          def line_items(hash)
            hash['items']['result']['items']['item']
          end

          def discount_applied_on_all_line_items?(discounts)
            discounts.length == 1
          end
        end
      end
    end
  end
end
