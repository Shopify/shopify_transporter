# frozen_string_literal: true

require_relative './product_mapping_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductExporter
        def initialize(soap_client: nil, database_adapter: nil)
          @client = soap_client
          @database_adapter = database_adapter
          @intermediate_file_name = 'magento_product_mappings.csv'
        end

        def export
          $stderr.puts 'Starting export...'
          products = base_products.map do |product|
            $stderr.puts "Fetching product: #{product[:product_id]}"
            with_attributes(product)
          end.compact
          apply_mappings(products)
        end

        private

        def base_products
          result = @client.call(:catalog_product_list, filters: nil).body
          result.to_hash.dig(:catalog_product_list_response, :store_view, :item) || []
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

        def with_attributes(product)
          product_with_base_attributes = product
            .merge(images: images_attribute(product[:product_id]))
            .merge(info_for(product[:product_id]))
            .merge(tags: product_tags(product[:product_id]))

          case product[:type]
          when 'simple'
            product_with_base_attributes.merge(inventory_quantity: inventory_quantity_for(product[:product_id]))
          else
            product_with_base_attributes
          end
        end

        def info_for(product_id)
          @client
            .call(:catalog_product_info, product_id: product_id)
            .body[:catalog_product_info_response][:info]
        end

        def inventory_quantity_for(product_id)
          @client
            .call(:catalog_inventory_stock_item_list, products: { product_id: product_id })
            .body[:catalog_inventory_stock_item_list_response][:result][:item][:qty].to_i
        end

        def images_attribute(product_id)
          @client
            .call(:catalog_product_attribute_media_list, product: product_id.to_i)
            .body[:catalog_product_attribute_media_list_response][:result][:item]
        end

        def product_tags(product_id)
          @client
            .call(:catalog_product_tag_list, product_id: product_id.to_i)
            .body[:catalog_product_tag_list_response][:result][:item]
        end
      end
    end
  end
end
