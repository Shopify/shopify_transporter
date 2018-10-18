# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'
require 'pry'
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
              percentage_discount(hash)
            ].compact
          end

          def shipping_discount(hash)
            shipping_discount_amount = fetch_value(hash, 'shipping_discount_amount')
            shipping_amount = fetch_value(hash, 'shipping_amount')
            if shipping_discount_amount > shipping_amount
              {
                code: hash['discount_description'],
                amount: shipping_discount_amount,
                type: 'shipping'
              }.stringify_keys
            end
          end

          def fixed_amount_discount(hash)
            discount_amount = discount_amount(hash)
            discount_percentage = discount_percentage(hash)
            if discount_amount > 0 && discount_percentage == 0
              {
                code: hash['discount_description'],
                amount: discount_amount,
                type: 'fixed_amount'
              }.stringify_keys
            end
          end

          def percentage_discount(hash)
            discount_amount = discount_amount(hash)
            discount_percentage = discount_percentage(hash)

            if discount_amount > 0 && discount_percentage != 0
              {
                code: hash['discount_description'],
                amount: discount_percentage,
                type: 'percentage'
              }.stringify_keys
            end
          end

          def discount_percentage(hash)
            percentage = 0
            return percentage unless hash.dig('items', 'result', 'items', 'item').present?

            if line_items(hash).is_a?(Hash)
              percentage = fetch_value(line_items(hash), 'discount_percent')
            else
              discounts = line_items(hash).map do |line_item|
                fetch_value(line_item, 'discount_percent')
              end.uniq
              percentage = discounts.first if discount_applied_on_all_line_items?(discounts)
            end
            percentage
          end

          def discount_amount(hash)
            hash['discount_amount'].present? ? hash['discount_amount'][1..-1].to_f : 0
          end

          def fetch_value(hash, key)
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
