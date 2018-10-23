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
            if fixed_amount_discount?(hash)
              {
                code: discount_code(hash),
                amount: discount_amount(hash),
                type: 'fixed_amount',
              }.stringify_keys
            end
          end

          def percentage_discount(hash)
            if percentage_discount?(hash)
              {
                code: discount_code(hash),
                amount: discount_percentage(hash),
                type: 'percentage',
              }.stringify_keys
            end
          end

          def discount_percentage(hash)
            if qualifies_for_percentage_discount?(hash)
              if line_items(hash).is_a?(Hash)
                value_as_float(line_items(hash), 'discount_percent')
              elsif line_items(hash).is_a?(Array)
                all_discount_percentages(hash).first
              end
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

          def qualifies_for_percentage_discount?(hash)
            return false unless line_items?(hash)

            return true if line_items(hash).is_a?(Hash) && value_as_float(line_items(hash), 'discount_percent') > 0

            all_discount_percentages(hash).length == 1 && all_discount_percentages(hash).first > 0
          end

          def line_items?(hash)
            hash.dig('items', 'result', 'items', 'item').present?
          end

          def line_items(hash)
            hash['items']['result']['items']['item']
          end

          def all_discount_percentages(hash)
            line_items(hash).map do |line_item|
              value_as_float(line_item, 'discount_percent')
            end.uniq
          end

          def fixed_amount_discount?(hash)
            discount_amount(hash) > 0 && !qualifies_for_percentage_discount?(hash)
          end

          def percentage_discount?(hash)
            discount_amount(hash) > 0 && qualifies_for_percentage_discount?(hash)
          end
        end
      end
    end
  end
end
