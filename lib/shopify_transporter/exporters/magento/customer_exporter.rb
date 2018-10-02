# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      class CustomerExporter
        def initialize(soap_client: nil, database_adapter: nil)
          @client = soap_client
          @database_adapter = database_adapter
        end

        def key
          :customer_id
        end

        def export
          base_customers.each do |customer|
            yield with_attributes(customer)
          end
        end

        private

        def with_attributes(base_customer)
          base_customer.merge(address_list: customer_address_list(base_customer[:customer_id]))
        end

        def base_customers
          Enumerator.new do |enumerator|
            @client.call_in_batches(method: :customer_customer_list, batch_index_column: 'customer_id').each do |batch|
              result = batch.body[:customer_customer_list_response][:store_view][:item] || []
              result = [result] unless result.is_a? Array
              result.each { |customer| enumerator << customer }
            end
          end
        end

        def customer_address_list(customer_id)
          @client.call(:customer_address_list, customer_id: customer_id).body
        end
      end
    end
  end
end
