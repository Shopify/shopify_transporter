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
      $stderr.puts "fetched item details for order #{order[:increment_id]}"
    end
  end

  def base_orders
    $stderr.puts "pulling order info from Magento..."
    base_orders = orders_starting_with('')
    $stderr.puts "\nfetched base information for all orders!"
    base_orders
  end

  def orders_starting_with(id_prefix)
    Timeout::timeout(TIMEOUT_DURATION, MagentoTimeoutError) do
      $stderr.print '.'
      order_list(id_prefix)
    end
  rescue MagentoTimeoutError
    (0..9).map do |digit|
      orders_starting_with("#{id_prefix}#{digit}")
    end.flatten.compact
  end

  def order_list(id_prefix)
    soap_client.call(
      :sales_order_list,
      message: {
        sessionId: soap_session_id,
        filters: filters.merge(filter_ids_starting_with(id_prefix)),
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
end

begin
  OrderExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
