# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class ShippingLines < Pipeline::Stage
          def convert(input, record)
            record.merge!(
              {
                shipping_lines: shipping_lines(input),
              }.stringify_keys
            )
          end

          private

          def shipping_lines(input)
            [
              {
                code: input['shipping_description'],
                title: input['shipping_description'],
                price: input['shipping_amount'],
                carrier_identifier: input['shipping_method'],
                tax_lines: shipping_tax_lines(input),
              }.stringify_keys,
            ]
          end

          def shipping_tax_lines(input)
            return unless input['shipping_tax_amount'].present? && input['shipping_tax_amount'].to_f != 0

            [
              {
                price: input['shipping_tax_amount'],
              }.stringify_keys,
            ]
          end
        end
      end
    end
  end
end
