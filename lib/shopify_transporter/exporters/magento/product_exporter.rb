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
          $stderr.puts "Starting export..."
          apply_mappings(base_products, product_mappings).compact
        end

        private

        def base_products
          result = @client.call(:catalog_product_list, filters: nil).body
          result[:catalog_product_list_response][:store_view][:item] || []
        end

        def product_mappings
          # dummy. TODO: generate and use real mapping file here!
          raw_mappings = CSV.read("magento_product_mappings.csv")

          {}.tap do |table|
            raw_mappings.each do |pair|
              table[pair[0]] ||= []
              table[pair[0]] << pair[1]
            end
          end
        end

        def apply_mappings(product_list, product_mappings)
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
