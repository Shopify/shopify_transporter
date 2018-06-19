require_relative './magento_customer_exporter.rb'

module ShopifyTransporter
  class MagentoExporter
    class MissingMagentoExporterError < ExportError; end

    def self.for(store_id, type, client)
      case type
      when 'customer'
        MagentoCustomerExporter
      else
        raise MissingMagentoExporterError
      end.new(store_id, client)
    end
  end
end
