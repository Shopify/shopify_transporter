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
      $stderr.puts "fetched customer: #{customer[:customer_id]}"
    end
  end

  def base_customers
    customers = soap_client.call(
      :customer_customer_list,
      message: {
        session_id: soap_session_id,
      }
    ).body

    customers[:customer_customer_list_response][:store_view][:item].select do |customer|
      customer[:store_id] == required_env_vars['MAGENTO_STORE_ID']
    end
  end

  def customer_address_list(customer_id)
    soap_client.call(
      :customer_address_list,
      message: { session_id: soap_session_id, customer_id: customer_id }
    ).body
  end
end

begin
  CustomerExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
