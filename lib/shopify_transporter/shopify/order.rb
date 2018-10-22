# frozen_string_literal: true
require 'active_support/inflector'
require 'csv'
require_relative 'attributes_helpers'
require_relative 'record'

module ShopifyTransporter
  module Shopify
    class Order < Record
      class << self
        include AttributesHelpers

        def header
          [
            'Name', 'Email', 'Financial Status', 'Fulfillment Status', 'Currency',
            'Buyer Accepts Marketing', 'Cancel Reason', 'Cancelled At', 'Closed At', 'Tags', 'Note',
            'Phone', 'Referring Site', 'Processed At', 'Source name', 'Total discounts', 'Total weight',
            'Total Tax', 'Shipping Company', 'Shipping Name', 'Shipping Phone', 'Shipping First Name',
            'Shipping Last Name', 'Shipping Address1', 'Shipping Address2', 'Shipping City',
            'Shipping Province', 'Shipping Province Code', 'Shipping Zip', 'Shipping Country',
            'Shipping Country Code', 'Billing Company', 'Billing Name', 'Billing Phone',
            'Billing First Name', 'Billing Last Name', 'Billing Address1', 'Billing Address2',
            'Billing City', 'Billing Province', 'Billing Province Code', 'Billing Zip',
            'Billing Country', 'Billing Country Code', 'Lineitem name', 'Lineitem quantity',
            'Lineitem price', 'Lineitem sku', 'Lineitem requires shipping', 'Lineitem taxable',
            'Lineitem fulfillment status', 'Tax 1 Title', 'Tax 1 Price', 'Tax 1 Rate', 'Tax 2 Title',
            'Tax 2 Price', 'Tax 2 Rate', 'Tax 3 Title', 'Tax 3 Price', 'Tax 3 Rate',
            'Transaction amount', 'Transaction kind', 'Transaction status',
            'Metafield Namespace', 'Metafield Key', 'Metafield Value', 'Metafield Value Type'
          ].to_csv
        end

        def keys
          %w(name).freeze
        end

        def columns
          @columns ||= header.split(',').map do |header_column|
            normalize_string(header_column)
          end
        end
      end

      def to_csv
        CSV.generate do |csv|
          csv << top_level_row_values
          line_item_row_values.each { |row| csv << row }
          transaction_row_values.each { |row| csv << row }
          metafield_row_values.each { |row| csv << row }
        end
      end

      private

      TOP_LEVEL_ATTRIBUTES = %w(
        name email financial_status fulfillment_status currency
        buyer_accepts_marketing cancel_reason cancelled_at closed_at tags note
        phone referring_site processed_at source_name total_discounts total_weight total_tax
      )

      ADDRESS_ATTRIBUTES = %w(
        company name phone first_name last_name address1 address2 city province province_code zip country country_code
      )

      LINE_ITEM_PREFIX = 'lineitem_'

      LINE_ITEM_ATTRIBUTES = %w(
        name quantity price sku requires_shipping taxable fulfillment_status
      )

      TRANSACTION_PREFIX = 'transaction_'

      TRANSACTION_ATTRIBUTES = %w(
        amount kind status
      )

      def address_hash_for(address_hash, prefix)
        return {} if address_hash.blank?

        address_hash.transform_keys { |k| "#{prefix}#{k}" }
      end

      def top_level_row_values
        top_level_hash = record_hash
          .slice(*TOP_LEVEL_ATTRIBUTES)
          .merge(address_hash_for(record_hash['billing_address'], 'billing_'))
          .merge(address_hash_for(record_hash['shipping_address'], 'shipping_'))
        self.class.has_values?(top_level_hash) ? row_values_from(top_level_hash) : nil
      end

      def tax_line_hash(line_item_hash)
        return {} if line_item_hash['tax_lines'].blank?

        line_item_hash['tax_lines'].each_with_index.map do |tax_line, index|
          tax_line.each_with_object({}) do |(key, val), hash|
            hash["tax_#{index + 1}_#{key}"] = val
          end
        end.reduce({}, :merge)
      end

      def line_item_row_values
        return [] unless record_hash['line_items']

        record_hash['line_items'].map do |line_item_hash|
          line_item = line_item_hash.slice(*LINE_ITEM_ATTRIBUTES)
            .transform_keys! { |k| "#{LINE_ITEM_PREFIX}#{k}" }
            .merge(tax_line_hash(line_item_hash))

          row_values_from(line_item) if self.class.has_values?(line_item)
        end.compact
      end

      def transaction_row_values
        return [] unless record_hash['transactions']

        record_hash['transactions'].map do |transaction_hash|
          transaction = transaction_hash.slice(*TRANSACTION_ATTRIBUTES)
            .transform_keys! { |k| "#{TRANSACTION_PREFIX}#{k}" }

          row_values_from(transaction) if self.class.has_values?(transaction)
        end.compact
      end
    end
  end
end
