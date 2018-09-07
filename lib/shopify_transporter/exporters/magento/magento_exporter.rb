require_relative './magento_customer_exporter.rb'
require_relative './magento_order_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class MagentoExporter
        class MissingMagentoExporterError < ExportError; end

        def self.for(type, store_id, client)
          case type
          when 'customer'
            MagentoCustomerExporter
          when 'order'
            MagentoOrderExporter
          else
            raise MissingMagentoExporterError
          end.new(store_id, client)
        end
      end
    end
  end
end
