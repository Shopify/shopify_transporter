# frozen_string_literal: true
require 'savon'
require 'json'

require 'active_support'
require 'active_support/core_ext'

require_relative 'transporter_exporter'

class OrderExporter < TransporterExporter
  START_DATE = 5.years.ago
  END_DATE = Time.now
  INTERVAL_SIZE = 2.weeks

  def run
    puts "["
    print_orders
  ensure
    puts "]"
  end

  private

  def key
    :increment_id
  end

  def print_orders
    base_orders.each_with_index do |order, index|
      next if skip?(order)

      begin
        order.merge!('items' => items_for(order))
      rescue => e
        print_order_details_error(order, e)
      end

      print_order(order, index)
    end
  end

  def print_order(order, index)
    print_json_seperator(index)
    puts JSON.pretty_generate(order)
    $stderr.puts "Exported order: #{order[:increment_id]}"
  end

  def print_order_details_error(order, e)
    $stderr.puts "***"
    $stderr.puts "Warning:"
    $stderr.puts "Encountered an error with fetching details for order with id: #{order[:increment_id]}"
    $stderr.puts JSON.pretty_generate(order)
    $stderr.puts "The exact error was:"
    $stderr.puts "#{e.class}: "
    $stderr.puts e.message
    $stderr.puts "-"
    $stderr.puts "Exporting the order (#{order[:increment_id]}) without its details."
    $stderr.puts "Continuing with the next order."
    $stderr.puts "***"
  end

  def base_orders
    $stderr.puts "Retrieving orders in the specified date range from Magento..."

    base_orders = orders_in_daterange(START_DATE, END_DATE, INTERVAL_SIZE)
    $stderr.puts "\nFetched the order list, starting to process each order."
    base_orders
  end

  def orders_in_daterange(start_date, end_date, interval_length)
    fetched_orders = []
    loop do |date, orders|
      fetched_orders += order_list(start_date, start_date + interval_length)
      start_date += interval_length
      break if start_date > end_date
    end
    fetched_orders
  end

  def order_list(start_date, end_date)
    result = soap_client.call(
      :sales_order_list,
      message: {
        sessionId: soap_session_id,
        filters: filters.merge(filter_by_date_range(start_date, end_date)),
      }
    ).body[:sales_order_list_response][:result][:item]

    case result
    when Array
      result
    when Hash
      [result]
    else
      []
    end
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
