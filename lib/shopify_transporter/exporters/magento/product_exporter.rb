# frozen_string_literal: true

require_relative './database_table_exporter.rb'
require_relative './database_cache.rb'
require_relative './product_options.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductExporter
        def initialize(soap_client: nil, database_adapter: nil)
          @client = soap_client
          @database_table_exporter = DatabaseTableExporter.new(database_adapter)
          @database_cache = DatabaseCache.new
          @product_options = ProductOptions.new(@database_table_exporter, @database_cache)
        end

        def key
          :product_id
        end

        def export
          apply_mappings(base_products).each do |product|
            yield with_attributes(product)
          end
        end

        private

        def base_products
          result = @client.call(:catalog_product_list, filters: nil).body
          result.to_hash.dig(:catalog_product_list_response, :store_view, :item) || []
        end

        def product_mappings
          @product_mappings ||= begin
            @database_table_exporter.export_table('catalog_product_relation', 'parent_id')

            {}.tap do |product_mapping_table|
              @database_cache.table('catalog_product_relation').each do |row|
                product_mapping_table[row['child_id']] = row['parent_id']
              end
            end
          end
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
            .merge(info_for(product))
            .merge(tags: product_tags(product[:product_id]))

          case product[:type]
          when 'simple'
            product_with_base_attributes
              .merge(inventory_quantity: inventory_quantity_for(product[:product_id]))
              .merge(variant_option_values(product_with_base_attributes))
          when 'configurable'
            product_with_base_attributes
              .merge(configurable_product_options(product_with_base_attributes))
          else
            product_with_base_attributes
          end
        end

        def variant_option_values(simple_product)
          @product_options.shopify_variant_options(simple_product)
        end

        def configurable_product_options(product)
          @product_options.shopify_option_names(product[:product_id])
        end

        def info_for(product)
          additional_attributes = if product[:parent_id]
            @product_options.lowercase_option_names(product[:parent_id])
          end

          attributes = if additional_attributes
            { 'additional_attributes' => { item: additional_attributes } }
          end

          @client
            .call(
              :catalog_product_info,
              product_id: product[:product_id],
              attributes: attributes
            )
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
