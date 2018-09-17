# frozen_string_literal: true

require_relative './product_mapping_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductExporter
        def initialize(store_id: nil, soap_client: nil, database_adapter: nil)
          @client = soap_client
          @store_id = store_id
          @intermediate_file_name = 'magento_product_mappings.csv'
          @database_adapter = database_adapter
        end

        def export
          $stderr.puts 'Starting export...'
          apply_mappings(base_products.compact)
        end

        private

        def base_products
          result = @client.call(:catalog_product_list, filters: nil).body
          result[:catalog_product_list_response][:store_view][:item] || []
        end

        def product_mappings
          product_mapping_exporter.write_mappings(@intermediate_file_name)

          @product_mappings ||= {}.tap do |product_mapping_table|
            CSV.read(@intermediate_file_name).each do |(parent_id, child_id)|
              product_mapping_table[child_id] = parent_id
            end
          end
        end

        def product_mapping_exporter
          @product_mapping_exporter ||= ProductMappingExporter.new(@database_adapter)
        end

        def apply_mappings(product_list)
          product_list.map do |product|
            case product[:type]
            when 'simple'
              merge_simple_product_with_parent(product, product_mappings)
            else
              product
            end
          end
        end

        def merge_simple_product_with_parent(product, product_mappings)
          return product unless product_mappings[product[:product_id]].present?

          product.merge(parent_id: product_mappings[product[:product_id]])
        end
      end
    end
  end
end
