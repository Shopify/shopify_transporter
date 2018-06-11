# frozen_string_literal: true
require 'savon'
require 'json'

require_relative 'transporter_exporter.rb'

class CustomerExporter < TransporterExporter
  def run
    puts JSON.pretty_generate(customers)
  end

  private

  def key
    :customer_id
  end

  def customers
    base_customers.each_with_object([]) do |customer, customers|
      next if skip?(customer)

      customers << customer.merge(address_list: customer_address_list(customer[:customer_id]))
      $stderr.puts "fetched address details for customer: #{customer[:customer_id]}"
    end
  end

  def base_customers
    $stderr.puts "pulling customer info from Magento..."
    base_customers = customers_starting_with('')
    $stderr.puts "\nfetched base information for all customers!"
    base_customers
  end

  def customers_starting_with(id_prefix)
    Timeout::timeout(TIMEOUT_DURATION, MagentoTimeoutError) do
      $stderr.print '.'
      customer_list(id_prefix)
    end
  rescue MagentoTimeoutError
    (0..9).map do |digit|
      customers_starting_with("#{id_prefix}#{digit}")
    end.flatten.compact
  end

  def customer_list(id_prefix)
    soap_client.call(
      :customer_customer_list,
      message: {
        sessionId: soap_session_id,
        filters: filters.merge(filter_ids_starting_with(id_prefix)),
      }
    ).body[:customer_customer_list_response][:store_view][:item]
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
end

begin
  CustomerExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
