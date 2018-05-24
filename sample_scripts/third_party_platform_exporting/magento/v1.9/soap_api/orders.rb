# frozen_string_literal: true
require 'savon'
require 'json'

require_relative 'transporter_exporter'

class OrderExporter < TransporterExporter
  def run
    orders_for(required_env_vars['MAGENTO_STORE_ID']).each do |order|
      next if skip?(order)

      puts JSON.pretty_generate(order.merge('items' => items_for(order)))
    end
  end

  private

  def orders
    soap_client.call(
      :sales_order_list,
      message: { session_id: soap_session_id }
    ).body[:sales_order_list_response][:result][:item]
  end

  def orders_for(store_id)
    orders.select do |order|
      order[:store_id] == store_id
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
