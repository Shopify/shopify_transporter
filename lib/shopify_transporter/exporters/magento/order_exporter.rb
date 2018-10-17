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
            begin
              yield with_attributes(order)
            rescue Savon::Error => e
              print_order_details_error(order, e)
              yield order
            end
          end
        end

        private

        def with_attributes(base_order)
          base_order.merge(
            items: remove_child_items(info_for(base_order[:increment_id])),
          )
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

        def remove_child_items(items)
          all_products = items.dig(:result, :items, :item)
          return items unless all_products.present? && all_products.is_a?(Array)

          {
            result: {
              items: {
                item: combine_parent_and_child_info(all_products)
              }
            }
          }
        end

        def combine_parent_and_child_info(products)
          products.group_by { |product| product[:sku] }.map do |sku, sub_products|
            return sub_products unless sub_products.size == 2

            child_name = sub_products.find { |sub_product| simple?(sub_product) }[:name]
            sub_products.find { |sub_product| configurable?(sub_product) }.merge(name: child_name)
          end
        end

        def simple?(sub_product)
          sub_product[:product_type] == 'simple'
        end

        def configurable?(sub_product)
          sub_product[:product_type] == 'configurable'
        end

        def print_order_details_error(order, e)
          $stderr.puts '***'
          $stderr.puts 'Warning:'
          $stderr.puts "Encountered an error with fetching details for order with id: #{order[:order_id]}"
          $stderr.puts JSON.pretty_generate(order)
          $stderr.puts 'The exact error was:'
          $stderr.puts "#{e.class}: "
          $stderr.puts e.message
          $stderr.puts '-'
          $stderr.puts "Exporting the order (#{order[:order_id]}) without its details."
          $stderr.puts 'Continuing with the next order.'
          $stderr.puts '***'
        end
      end
    end
  end
end
