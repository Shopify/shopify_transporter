# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class OrderExporter
        def initialize(soap_client: nil, database_adapter: nil)
          @client = soap_client
          @database_adapter = database_adapter
        end

        def key
          :order_id
        end

        def export
          base_orders.each do |order|
            yield with_attributes(order)
          end
        end

        private

        def with_attributes(base_order)
          base_order.merge(items: info_for(base_order[:increment_id]))
        end

        def base_orders
          Enumerator.new do |enumerator|
            @client.call_in_batches(method: :sales_order_list, batch_index_column: 'order_id').each do |batch|
              result = batch.body[:sales_order_list_response][:result][:item] || []
              result = [result] unless result.is_a? Array
              result.each { |order| enumerator << order }
            end
          end
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
