# frozen_string_literal: true
require 'savon'
require 'json'

require_relative 'transporter_exporter.rb'

class CustomerExporter < TransporterExporter
  def run
    customers.each do |customer|
      next if skip?(customer)

      customer[:address_list] = customer_address_list(customer[:customer_id])
      puts JSON.pretty_generate(customer)
    end
  end

  private

  def customers
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
