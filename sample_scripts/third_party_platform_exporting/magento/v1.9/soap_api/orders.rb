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
      message: { session_id: soap_session_id }
    ).body[:sales_order_list_response][:result][:item].select do |order|
      order[:store_id] == required_env_vars['MAGENTO_STORE_ID']
    end
  end

  def items_for(order)
    soap_client.call(
      :sales_order_info,
      message: {
        session_id: soap_session_id,
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
