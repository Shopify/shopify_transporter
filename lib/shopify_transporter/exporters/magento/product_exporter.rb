# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductExporter
        def initialize(store_id: nil, client: nil, database_adapter: nil)
          @client = client
          @store_id = store_id
          @intermediate_file_name = 'transporter/magento_product_mappings.csv'
          @database_adapter: database_adapter
        end

        def export
          $stderr.puts 'Starting export...'
          apply_mappings(base_products).compact
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
              product_mapping_table[parent_id] ||= []
              product_mapping_table[parent_id] << child_id
            end
          end
        end

        def product_mapping_exporter
          @product_mapping_exporter ||= ProductMappingExporter.new(database_adapter: @database_adapter)

        def apply_mappings(product_list)
          product_list.map do |product|
            case product[:type]
            when 'configurable'
              product.merge(simple_product_ids: product_mappings[product[:product_id]])
            else
              product
            end
          end
        end
      end
    end
  end
end
