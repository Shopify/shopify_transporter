# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class OrderExporter
        def initialize(soap_client: nil, database_adapter: nil)
          @client = soap_client
          @database_adapter = database_adapter
        end

        def export
          $stderr.puts 'Starting export...'
          base_orders.map do |order|
            $stderr.puts "Fetching order: #{order[:increment_id]}..."
            order.merge(items: info_for(order[:increment_id]))
          end.compact
        end

        private

        def base_orders
          result = @client.call(:sales_order_list, filters: nil).body
          result[:sales_order_list_response][:result][:item] || []
        end

        def info_for(order_increment_id)
          @client
            .call(:sales_order_info, order_increment_id: order_increment_id)
            .body[:sales_order_info_response]
        end
      end
    end
  end
end
