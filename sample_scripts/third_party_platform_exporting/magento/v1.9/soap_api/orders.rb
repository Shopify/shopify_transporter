# frozen_string_literal: true
require 'savon'
require 'json'
require 'pry'

require_relative 'transporter_exporter'

class OrderExporter < TransporterExporter
  def run
    binding.pry
    puts JSON.pretty_generate(orders)
  end

  private

  def key
    :increment_id
  end

  def filters
    {
      filter: {
        item: {
          key: 'store_id', 
          value: '1',
        }
      }
    }
  end

  # The product ID of the parent configurable is: 665548
  def complex_filters 
    {
      complex_filter: [
        item: [
          {
            key: 'created_at',
            value: {
                key: 'from',
                value: '2018-05-01 00:00:00',
            }
          },
          {
            key: 'created_at',
            value: {
                key: 'to',
                value: '2018-06-01 00:00:00',
            }
          },
        ] 
      ]
    }
  end

  def orders
    base_orders.each_with_object([]) do |order, orders|
      next if skip?(order)

      orders << order.merge('items' => items_for(order))
      $stderr.puts "fetched order #{order[:increment_id]}"
    end
  end

  def base_orders
    soap_client.call(
      :sales_order_list,
      message: {
        sessionId: soap_session_id,
        filters: filters.merge(complex_filters),
      }
    ).body
  end

  def items_for(order)
    soap_client.call(
      :sales_order_info,
      message: {
        sessionId: soap_session_id,
        order_increment_id: order[:increment_id],
      }
    ).body[:sales_order_info_response]
  end
end

begin
  OrderExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
