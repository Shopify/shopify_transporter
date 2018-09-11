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
          x = CSV.read("magento_product_mappings.csv")

          keys = x.map(&:first)

          keys.map do |key|
            values = []
            x.each do |pair|
              values << pair[1] if key == pair[0]
            end
            [key, values]
          end.to_h
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
