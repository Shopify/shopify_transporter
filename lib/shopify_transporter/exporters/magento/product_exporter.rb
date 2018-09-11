# frozen_string_literal: true
require 'pry'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductExporter
        def initialize(store_id: nil, client: nil)
          @client = client
          @store_id = store_id
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
          @product_mappings ||= {}.tap do |product_mapping_table|
            # TODO: generate and use real mapping file here!
            CSV.read('magento_product_mappings.csv').each do |(parent_id, child_id)|
              product_mapping_table[parent_id] ||= []
              product_mapping_table[parent_id] << child_id
            end
          end
        end

        def apply_mappings(product_list)
          product_list.map do |product|
            if product[:type] == 'configurable'
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
