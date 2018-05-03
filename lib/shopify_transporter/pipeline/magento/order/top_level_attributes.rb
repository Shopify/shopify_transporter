# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class TopLevelAttributes < Pipeline::Stage
          def convert(hash, record)
            record.merge!(
              {
                name: hash['increment_id'],
                email: hash['customer_email'],
                processed_at: hash['created_at'],
                subtotal_price: hash['subtotal'],
                total_tax: hash['tax_amount'],
                total_price: hash['grand_total'],
              }.stringify_keys
            )
            customer = build_customer(hash)
            record['customer'] = customer unless customer.empty?
            record
          end

          private

          def build_customer(hash)
            {
              email: hash['customer_email'],
              first_name: hash['customer_firstname'],
              last_name: hash['customer_lastname'],
            }.stringify_keys
          end
        end
      end
    end
  end
end
