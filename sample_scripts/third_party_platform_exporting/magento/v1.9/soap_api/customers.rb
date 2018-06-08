# frozen_string_literal: true
require 'savon'
require 'json'
require 'timeout'

require_relative 'transporter_exporter.rb'

TIMEOUT_DURATION = 8

class MagentoTimeoutError < TransporterExporter::ExportError
end

class CustomerExporter < TransporterExporter
  def run
    puts JSON.pretty_generate(customers)
  end

  private

  def key
    :customer_id
  end

  def customers
    $stderr.puts "pulling customer info from Magento..."
    base_customers = base_customers_starting_with('1')
    $stderr.puts "\nfetched base information for all customers!"

    base_customers.each_with_object([]) do |customer, customers|
      next if skip?(customer)

      customers << customer.merge(address_list: customer_address_list(customer[:customer_id]))
      $stderr.puts "fetched address details for customer: #{customer[:customer_id]}"
    end
  end

  def base_customers_starting_with(prefix)
    begin
      base_customers = Timeout::timeout(TIMEOUT_DURATION, MagentoTimeoutError) do
        soap_client.call(
          :customer_customer_list,
          message: {
            sessionId: soap_session_id,
            filters: filters.merge(filter_ids_starting_with(prefix)),
          }
        ).body[:customer_customer_list_response][:store_view][:item]
      end
      print '.'
      base_customers
    rescue MagentoTimeoutError
      (0..9).map do |digit|
        base_customers_starting_with("#{prefix}#{digit}")
      end.flatten.compact
    end
  end

  def customer_address_list(customer_id)
    soap_client.call(
      :customer_address_list,
      message: {
        sessionId: soap_session_id,
        customerId: customer_id ,
      }
    ).body
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

  def filter_ids_starting_with(prefix)
    expr = "^#{prefix}.*$"
    {
      complex_filter: [
        item: [
          {
            key: 'customer_id',
            value: {
                key: 'regexp',
                value: expr,
            }
          }
        ]
      ]
    }
  end
end

begin
  CustomerExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
