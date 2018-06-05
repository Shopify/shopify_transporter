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
        sessionId: soap_session_id,
        filters: filters.merge(complex_filters),
      }
    ).body

    customers[:customer_customer_list_response][:store_view][:item].select do |customer|
      customer[:store_id] == required_env_vars['MAGENTO_STORE_ID']
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

  def complex_filters
    {
      complex_filter: [
        item: [
          {
            key: 'customer_id',
            value: {
                key: 'from',
                value: '5382',
            }
          },
          {
            key: 'customer_id',
            value: {
                key: 'to',
                value: '5400',
            }
          },
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
