# frozen_string_literal: true
require 'savon'
require 'json'
require 'pry'

require_relative 'transporter_exporter.rb'
class Observer

  def notify(operation_name, builder, globals, locals)
    puts builder.build_document
  end

end

Savon.observers << Observer.new

class ProductExporter < TransporterExporter
  def run
    #binding.pry
    products = product_info(1)
    #products = base_products
    puts "before binding"
    binding.pry
  end

  private

  # The product ID of this is: 665548
  def filters
    {
      filter: {
        item: {
          key: 'sku', 
          value: 'RIP-HAU-GSHAW8-FA17',
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
            key: 'sku',
            value: {
                key: 'like',
                value: 'RIP-HAU-GSHAW8-FA17%',
            }
          },
          {
            key: 'type',
            value: {
                key: '=',
                value: 'simple',
            }
          },
        ] 
      ]
    }
  end

  def product_info(product_id)
    soap_client.call(
      :catalog_product_list,
      message: { sessionId: soap_session_id, filters: filters}
    ).body
  end
end

begin
  ProductExporter.new.run
rescue TransporterExporter::ExportError => e
  puts "error: #{e}"
  exit(1)
end
