# frozen_string_literal: true
require_relative 'record'
require 'active_support/inflector'
require 'csv'
require 'pry'
module ShopifyTransporter
  module Shopify
    class Customer < Record
      class << self
        def header
          columns.map(&:titleize).to_csv
        end

        def keys
          %w(email phone).freeze
        end

        def columns
          %w(
            first_name last_name email phone accepts_marketing tags
            note tax_exempt company address1 address2 city province
            province_code zip country country_code metafield_namespace
            metafield_key metafield_value metafield_value_type
          ).freeze
        end
      end

      def to_csv
        CSV.generate do |csv|
          csv << top_level_row_values
          address_row_values.each { |row| csv << row }
          metafield_row_values.each { |row| csv << row }
        end
      end

      private

      TOP_LEVEL_ATTRIBUTES = %w(
        first_name last_name email phone
        accepts_marketing
        tags
        note
        tax_exempt
      ).freeze

      ADDRESS_ATTRIBUTES = %w(
        first_name last_name phone
        company
        address1 address2
        city
        province province_code zip
        country country_code
      ).freeze

      SHARED_ADDRESS_ATTRIBUTES = %w(
        first_name last_name phone
      ).freeze

      def top_level_row_values
        base_hash.merge(record_hash.slice(*TOP_LEVEL_ATTRIBUTES))
          .merge(default_address_without_name_and_phone)
          .values
      end

      def default_address_without_name_and_phone
        return {} unless record_hash.dig('addresses').present?
        default_address = record_hash['addresses'][0]
        %w(first_name last_name phone).each { |key| default_address.delete(key) }
        default_address
      end

      def address_row_values
        return [] unless record_hash['addresses']
        record_hash['addresses'].drop(1).map do |address_hash|
          address = address_hash.slice(*ADDRESS_ATTRIBUTES)
          populate_missing_address_attributes!(address)
          row_values_from(address) if self.class.has_values?(address)
        end.compact
      end

      def populate_missing_address_attributes!(address)
        SHARED_ADDRESS_ATTRIBUTES.each do |shared_attribute|
          address[shared_attribute] = record_hash[shared_attribute] if address[shared_attribute].nil?
        end
      end
    end
  end
end
