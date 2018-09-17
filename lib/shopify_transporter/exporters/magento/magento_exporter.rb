# frozen_string_literal: true

require_relative './customer_exporter.rb'
require_relative './order_exporter.rb'
require_relative './product_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class MissingExporterError < ExportError; end

      class MagentoExporter
        def self.for(type: nil, store_id: nil, soap_client: nil, database_adapter: nil)
          case type
          when 'customer'
            CustomerExporter
          when 'order'
            OrderExporter
          when 'product'
            ProductExporter
          else
            raise MissingExporterError
          end.new(store_id: store_id, soap_client: soap_client, database_adapter: database_adapter)
        end
      end
    end
  end
end
