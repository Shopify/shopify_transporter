# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductOptions
        def initialize(database_table_exporter, database_cache)
          @database_table_exporter = database_table_exporter
          @database_cache = database_cache

          export_required_tables
        end

        def shopify_option_names(parent_product_id)
          option_names(parent_product_id).each_with_index.with_object({}) do |(option_name, index), obj|
            obj["option#{index + 1}_name".to_sym] = option_name
          end
        end

        def lowercase_option_names(parent_product_id)
          option_names(parent_product_id).map(&:downcase)
        end

        def shopify_variant_options(simple_product)
          return {} unless simple_product_has_required_option_keys(simple_product)

          parent_product_options = lowercase_option_names(simple_product[:parent_id])
          variant_attributes = simple_product[:additional_attributes][:item]
          parent_product_options.each_with_index.with_object({}) do |(option_name, index), obj|
            option_value_id = fetch_option_value_id(option_name, variant_attributes)

            obj["option#{index + 1}_name".to_sym] = option_name.capitalize
            obj["option#{index + 1}_value".to_sym] = option_value(option_value_id)
          end
        end

        private

        def option_names(product_id)
          option_lookup[product_id] || []
        end

        def option_value(soap_value_id)
          option_value_lookup[soap_value_id] || nil
        end

        def fetch_option_value_id(option_name, variant_attributes)
          option_attribute_hash = variant_attributes.select do |attribute|
            attribute[:key] == option_name
          end.first

          return nil if option_attribute_hash.nil?
          option_attribute_hash[:value]
        end

        def simple_product_has_required_option_keys(simple_product)
          simple_product.key?(:parent_id) && simple_product.key?(:additional_attributes)
        end

        def export_required_tables
          @database_table_exporter.export_table('catalog_product_super_attribute', 'product_super_attribute_id')
          @database_table_exporter.export_table('catalog_product_super_attribute_label', 'value_id')
          @database_table_exporter.export_table('eav_attribute_option_value', 'value_id')
        end

        def option_lookup
          @option_lookup ||= @database_cache
            .table('catalog_product_super_attribute')
            .each_with_object({}) do |attribute, option_hash|
            option_hash[attribute['product_id']] ||= []
            option_hash[attribute['product_id']] << option_label_lookup[attribute['product_super_attribute_id']]
          end
        end

        def option_label_lookup
          @option_label_lookup ||= @database_cache
            .table('catalog_product_super_attribute_label')
            .each_with_object({}) do |label, label_lookup|
            label_lookup[label['product_super_attribute_id']] = label['value']
          end
        end

        def option_value_lookup
          @option_value_lookup ||= begin
            soap_value_id_column_key = 'option_id'

            @database_cache
              .table('eav_attribute_option_value')
              .each_with_object({}) do |option_value, value_lookup|
              value_lookup[option_value[soap_value_id_column_key]] = option_value['value']
            end
          end
        end
      end
    end
  end
end
