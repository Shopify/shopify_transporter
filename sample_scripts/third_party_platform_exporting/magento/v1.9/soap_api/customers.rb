# frozen_string_literal: true
require 'savon'
require 'json'
require 'pry'

require_relative 'transporter_exporter.rb'

class CustomerExporter < TransporterExporter
  def run
    binding.pry
    puts JSON.pretty_generate(customers)
  end

  private

  def key
    :customer_id
  end

  def filters
    {
      filter: {
        item: {
          key: 'store_id', 
          value: '1',
        }
      }
    }
  end

  # The product ID of the parent configurable is: 665548
  def complex_filters 
    {
      complex_filter: [
        item: [
          {
            key: 'created_at',
            value: {
                key: 'from',
                value: '2018-05-01 00:00:00',
            }
          },
          {
            key: 'created_at',
            value: {
                key: 'to',
                value: '2018-06-01 00:00:00',
            }
          },
        ] 
      ]
    }
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
  end

  def customer_address_list(customer_id)
    soap_client.call(
      :customer_address_list,
      message: { sessionId: soap_session_id, customer_id: customer_id }
    ).body
  end
end

begin
  CustomerExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
