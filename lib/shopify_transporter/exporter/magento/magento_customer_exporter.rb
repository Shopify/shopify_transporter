# frozen_string_literal: true
module ShopifyTransporter
  class MagentoCustomerExporter
    attr_accessor :client, :store_id

    def initialize(store_id, client)
      @client = client
      @store_id = store_id
    end

    def export
      puts "starting export..."
      base_customers.map do |customer|
        puts "fetching customer: #{customer[:customer_id]}..."
        customer.merge(address_list: customer_address_list(customer[:customer_id]))
      end.compact
    end

    private

    def base_customers
      result = client.call(:customer_customer_list, filters: filters).body
      result[:customer_customer_list_response][:store_view][:item] || []
    end

    def customer_address_list(customer_id)
      client.call(:customer_address_list, customer_id: customer_id).body
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
