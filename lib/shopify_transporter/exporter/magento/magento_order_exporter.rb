# frozen_string_literal: true
module ShopifyTransporter
  class MagentoOrderExporter
    attr_accessor :client, :store_id

    def initialize(store_id, client)
      @client = client
      @store_id = store_id
    end

    def export
      puts "starting export..."
      base_orders.map do |order|
        puts "fetching order: #{order[:increment_id]}..."
        order.merge(items: info_for(order[:increment_id]))
      end.compact
    end

    private

    def base_orders
      result = client.call(:sales_order_list, filters: filters).body
      result[:sales_order_list_response][:result][:item] || []
    end

    def info_for(order_increment_id)
      client.call(:sales_order_info, order_increment_id: order_increment_id).body[:sales_order_info_response][:result]
      binding.pry
    end

    def filters
      {
        filter: {
          item: {
            key: 'store_id',
            value: store_id,
          }
        }
      }
    end
  end
end
