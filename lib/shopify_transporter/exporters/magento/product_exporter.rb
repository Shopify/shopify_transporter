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
          base_products.each do |product|
            begin # rubocop:disable Style/RedundantBegin
              yield with_attributes(product)
            rescue Savon::Error => e
              print_product_details_error(product, e)
              yield product
            end
          end
        end

        private

        def base_products
          Enumerator.new do |enumerator|
            @client.call_in_batches(method: :catalog_product_list, batch_index_column: 'product_id').each do |batch|
              result = batch.body[:catalog_product_list_response][:store_view][:item] || []
              result = [result] unless result.is_a?(Array)
              with_parent_mappings(result).each { |product| enumerator << product }
            end
          end
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

        def with_parent_mappings(product_list)
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
              .merge(categories: categories_for(product_with_base_attributes))
              .merge(inventory_quantity: inventory_quantity_for(product[:product_id]))
              .merge(variant_option_values(product_with_base_attributes))
          when 'configurable'
            product_with_base_attributes
              .merge(categories: categories_for(product_with_base_attributes))
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
          additional_attributes = @product_options.lowercase_option_names(product[:parent_id]) if product[:parent_id]
          attributes = { 'additional_attributes' => { item: additional_attributes } } if additional_attributes

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

        def categories_for(product)
          categories = []

          if product[:categories][:item]
            if product[:categories][:item].is_a? Array
              product[:categories][:item].each do |category_id|
                categories.push(@client
                  .call(:catalog_category_info, category_id: category_id.to_i )
                  .body[:catalog_category_info_response][:info])
              end
            else
              categories.push(@client
                .call(:catalog_category_info, category_id: product[:categories][:item].to_i )
                .body[:catalog_category_info_response][:info])
            end
          end

          return categories
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

        def print_product_details_error(product, e)
          $stderr.puts '***'
          $stderr.puts 'Warning:'
          $stderr.puts "Encountered an error with fetching details for product with id: #{product[:product_id]}"
          $stderr.puts JSON.pretty_generate(product)
          $stderr.puts 'The exact error was:'
          $stderr.puts "#{e.class}: "
          $stderr.puts e.message
          $stderr.puts '-'
          $stderr.puts "Exporting the product (#{product[:product_id]}) without its details."
          $stderr.puts 'Continuing with the next product.'
          $stderr.puts '***'
        end
      end
    end
  end
end
