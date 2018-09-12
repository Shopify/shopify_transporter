# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class CustomerExporter
        def initialize(store_id: nil, soap_client: nil, database_adapter: nil)
          @client = soap_client
          @store_id = store_id
        end

        def export
          $stderr.puts 'Starting export...'
          base_customers.map do |customer|
            $stderr.puts "Fetching customer: #{customer[:customer_id]}..."
            customer.merge(address_list: customer_address_list(customer[:customer_id]))
          end.compact
        end

        private

        def base_customers
          result = @client.call(:customer_customer_list, filters: filters).body
          result[:customer_customer_list_response][:store_view][:item] || []
        end

        def customer_address_list(customer_id)
          @client.call(:customer_address_list, customer_id: customer_id).body[:customer_address_list_response][:result]
        end

        def filters
          {
            filter: {
              item: {
                key: 'store_id',
                value: @store_id,
              },
            },
          }
        end
      end
    end
  end
end
