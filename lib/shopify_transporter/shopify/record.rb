# frozen_string_literal: true
module ShopifyTransporter
  module Shopify
    class Record
      METAFIELD_PREFIX = "metafield_"

      METAFIELD_ATTRIBUTES = %w(namespace key value value_type).freeze

      def initialize(hash = {})
        @record_hash = hash
      end

      def metafield_row_values
        return [] if @record_hash['metafields'].blank?
        @record_hash['metafields'].map do |metafield_hash|
          metafield = metafield_hash.slice(*METAFIELD_ATTRIBUTES)
          metafield.transform_keys! { |k| "#{METAFIELD_PREFIX}#{k}" }
          row_values_from(metafield) if self.class.has_values?(metafield)
        end.compact
      end

      class << self
        def header
          raise NotImplementedError
        end
      end

      def to_csv
        raise NotImplementedError
      end

      private

      attr_accessor :record_hash

      class << self
        def columns
          raise NotImplementedError
        end

        def keys
          raise NotImplementedError
        end

        def has_values?(hash)
          hash.except(*keys).any? { |_, v| v }
        end
      end

      def base_hash
        row = self.class.columns.each_with_object({}) { |column_name, hash| hash[column_name] = nil }
        row.merge(record_hash.slice(*self.class.keys))
      end

      def row_values_from(row_hash)
        base_hash.merge(row_hash).values_at(*self.class.columns)
      end
    end
  end
end
