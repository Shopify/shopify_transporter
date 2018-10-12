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
                currency: hash['order_currency_code'],
                cancelled_at: cancelled_at(hash),
                closed_at: closed_at(hash),
                processed_at: hash['created_at'],
                subtotal_price: hash['subtotal'],
                total_tax: hash['tax_amount'],
                total_price: hash['grand_total'],
                source_name: ORDER_ORIGINATED_FROM,
                total_weight: hash['weight'],
                financial_status: financial_status(hash),
                fulfillment_status: fulfillment_status(hash),
              }.stringify_keys
            )
            customer = build_customer(hash)
            record['customer'] = customer unless customer.empty?
            record
          end

          private

          ORDER_ORIGINATED_FROM = 'Magento'

          def build_customer(hash)
            {
              email: hash['customer_email'],
              first_name: hash['customer_firstname'],
              last_name: hash['customer_lastname'],
            }.stringify_keys
          end

          def financial_status(hash)
            order_state = hash['state']
            status = nil

            if order_state == 'Pending Payment'
              status = 'pending'
            elsif paid?(hash)
              status = 'paid'
            elsif partially_paid?(hash)
              status = 'partially_paid'
            elsif partially_refunded?(hash)
              status = 'partially_refunded'
            elsif refunded?(hash)
              status = 'refunded'
            end
            status
          end

          def fulfillment_status(hash)
            total_qty_ordered = hash['total_qty_ordered'].to_i
            total_qty_shipped = total_qty_shipped(hash)
            status = nil

            if total_qty_shipped == total_qty_ordered
              status = 'fulfilled'
            elsif total_qty_shipped > 0 && total_qty_shipped < total_qty_ordered
              status = 'partial'
            end
            status
          end

          def cancelled_at(hash)
            timestamp(hash, 'canceled') if cancelled?(hash)
          end

          def closed_at(hash)
            timestamp(hash, 'closed') if closed?(hash)
          end

          def cancelled?(hash)
            hash['state'] == 'canceled'
          end

          def closed?(hash)
            hash['state'] == 'closed'
          end

          def total_price(hash)
            hash['grand_total'].to_i
          end

          def total_paid(hash)
            return hash['total_paid'].to_i if hash['total_paid'].present?
            0
          end

          def total_refunded(hash)
            return hash['total_refunded'].to_i if hash['total_refunded'].present?
            0
          end

          def paid?(hash)
            total_price(hash) == total_paid(hash) && total_refunded(hash) == 0
          end

          def partially_paid?(hash)
            total_paid(hash) > 0 && total_paid(hash) < total_price(hash) && total_refunded(hash) == 0
          end

          def partially_refunded?(hash)
            total_refunded(hash) > 0 && total_refunded(hash) < total_paid(hash)
          end

          def refunded?(hash)
            total_refunded(hash) == total_paid(hash) && total_refunded(hash) != 0
          end

          def total_qty_shipped(hash)
            return 0 unless hash.dig('items', 'result', 'items', 'item').present?
            line_items = hash['items']['result']['items']['item']
            return line_items['qty_shipped'].to_i if line_items.is_a?(Hash)
            line_items.map { |line_item| line_item['qty_shipped'].to_i }.sum
          end

          def timestamp(hash, status)
            return unless hash.dig('items', 'result', 'status_history', 'item').present?

            history_items = hash['items']['result']['status_history']['item']
            return history_items['created_at'] if history_items.is_a?(Hash) && history_items['status'] == status

            last_applicable_history_item = history_items.select do |history|
              history['status'] == status
            end.last
            last_applicable_history_item['created_at'] if last_applicable_history_item.present?
          end
        end
      end
    end
  end
end
