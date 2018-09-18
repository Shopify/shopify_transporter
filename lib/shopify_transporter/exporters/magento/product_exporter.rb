# frozen_string_literal: true
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
          base_products.map do |product|
            $stderr.puts "Fetching products: #{product[:product_id]}"
            product.merge(items: info_for(product[:product_id]))
          end.compact
        end

        private

        def base_products
          result = @client.call(:catalog_product_list, filters: nil).body
          result[:catalog_product_list_response][:store_view][:item] || []
        end

        def info_for(product_id)
          @client
            .call(:catalog_product_info, product_id: product_id)
            .body
        end
      end
    end
  end
end
