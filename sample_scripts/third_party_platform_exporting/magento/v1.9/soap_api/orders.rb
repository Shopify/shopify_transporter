# frozen_string_literal: true
require 'savon'
require 'json'

require_relative 'transporter_exporter'

class OrderExporter < TransporterExporter
  def run
    puts JSON.pretty_generate(orders)
  end

  private

  def key
    :increment_id
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
    ).body[:sales_order_list_response][:result][:item]
  end

  def items_for(order)
    soap_client.call(
      :sales_order_info,
      message: {
        sessionId: soap_session_id,
        orderIncrementId: order[:increment_id],
      }
    ).body[:sales_order_info_response]
  end

  def filters
    {
      filter: {
        item: {
          key: 'store_id',
          value: required_env_vars['MAGENTO_STORE_ID'],
        }
      }
    }
  end

  def complex_filters
    {
      complex_filter: [
        item: [
          {
            key: 'created_at',
            value: {
                key: 'from',
                value: '2018-05-27 00:00:00',
            }
          },
          {
            key: 'created_at',
            value: {
                key: 'to',
                value: '2018-05-28 00:00:00',
            }
          },
        ]
      ]
    }
  end
end

begin
  OrderExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
