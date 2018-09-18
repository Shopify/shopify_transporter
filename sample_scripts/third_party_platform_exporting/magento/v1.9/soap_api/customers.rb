# frozen_string_literal: true
require 'savon'
require 'json'

require_relative 'transporter_exporter.rb'

class CustomerExporter < TransporterExporter
  def run
    puts "["
    print_customers
  ensure
    puts "]"
  end

  private

  def key
    :customer_id
  end

  def print_customers
    base_customers.each_with_index do |customer, index|
      next if skip?(customer)

      begin
        customer.merge!(address_list: customer_address_list(customer[:customer_id]))
        print_customer(customer, index)
      rescue => e
        print_customer_address_error(customer, e)
      end
    end
  end

  def print_customer(customer, index)
    print_json_seperator(index)
    puts JSON.pretty_generate(customer)
    $stderr.puts "Exported all details for customer: #{customer[:customer_id]}"
  end

  def print_customer_address_error(customer, e)
    $stderr.puts "***"
    $stderr.puts "Encountered error with fetching address for customer: #{customer[:customer_id]}"
    $stderr.puts JSON.pretty_generate(customer)
    $stderr.puts "The exact error was:"
    $stderr.puts "#{e.class}: "
    $stderr.puts e.message
    $stderr.puts "Continuing with next customer."
    $stderr.puts "***"
  end

  def print_json_seperator(index)
    puts "," unless index == 0
  end

  def base_customers
    $stderr.puts "Retrieving customer list from Magento using SOAP..."
    base_customers = customers_starting_with('')
    $stderr.puts "\nFetched customer list, starting to process each customer."
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
  puts "Encountered error: #{e}"
  exit(1)
end
