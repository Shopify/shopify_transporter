# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'
module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class Transactions < Pipeline::Stage
          def convert(input, record)
            record.merge(
              {
                transactions: transactions(input),
              }.stringify_keys
            )
          end

          private

          def transactions(input)
            [
              sale_transaction(input),
              refund_transaction(input),
            ].compact
          end

          def sale_transaction(input)
            return unless input['total_paid'].present?
            {
              amount: input['total_paid'].to_f,
              kind: 'sale',
              status: 'success',
            }.stringify_keys
          end

          def refund_transaction(input)
            return unless input['total_refunded'].present?
            {
              amount: input['total_refunded'].to_f,
              kind: 'refund',
              status: 'success',
            }.stringify_keys
          end
        end
      end
    end
  end
end
