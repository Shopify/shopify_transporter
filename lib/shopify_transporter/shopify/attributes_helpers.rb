# frozen_string_literal: true
require "active_support/core_ext/string"
module ShopifyTransporter
  module Shopify
    module AttributesHelpers
      def attributes_present?(row, *attributes)
        row.slice(*attributes).any? { |_, v| v.present? }
      end

      def add_prefix(prefix, *attributes)
        [*attributes].map { |attribute| "#{prefix}#{attribute}".to_sym }
      end

      def drop_prefix(row, prefix)
        row.transform_keys { |key| key.to_s.remove(prefix).to_sym }
      end

      def delete_empty_attributes(row)
        row.delete_if { |_, v| v.respond_to?(:empty?) && v.empty? }
      end

      def normalize_keys(row)
        row.compact.transform_keys { |key| normalize_string(key).to_sym }
      end

      def normalize_string(str)
        str.to_s.parameterize.underscore
      end

      def rename_fields(row, field_map)
        return row unless field_map.present?
        row = row.dup
        field_map.each { |from, to| row[to] = row.delete from if row[from].present? }
        row
      end

      def map_from_key_to_val(mapper, input)
        mapper.each_with_object({}) do |(key, value), attributes|
          attributes[value] = input[key] if input[key]
        end
      end

      def shopify_metafield_hash(key:, value:, value_type: 'string', namespace:)
        {
          'key' => key,
          'value' => value,
          'value_type' => value_type,
          'namespace' => namespace,
        }
      end
    end
  end
end
