# frozen_string_literal: true
require 'savon'
require 'json'

require 'active_support'
require 'active_support/core_ext'

require_relative 'transporter_exporter'

class OrderExporter < TransporterExporter
  START_DATE = 3.years.ago
  END_DATE = Time.now
  INTERVAL_SIZE = 2.weeks

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

    base_orders = orders_in_daterange(START_DATE, END_DATE, INTERVAL_SIZE)
    $stderr.puts "\nfetched base information for all orders!"
    base_orders
  end

  def orders_in_daterange(start_date, end_date, interval_length)
    fetched_orders = []
    loop do |date, orders|
      fetched_orders << order_list(start_date, start_date + interval_length)
      start_date += interval_length
      break if start_date > end_date
    end
    fetched_orders
  end

  def order_list(start_date, end_date)
    soap_client.call(
      :sales_order_list,
      message: {
        sessionId: soap_session_id,
        filters: filters.merge(filter_by_date_range(start_date, end_date)),
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

# begin
#   OrderExporter.new.run
# rescue TransporterExporter::ExportError => e
#   puts "error: #{e}"
#   exit(1)
# end
