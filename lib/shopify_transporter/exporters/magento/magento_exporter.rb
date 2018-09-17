# frozen_string_literal: true

require_relative './customer_exporter.rb'
require_relative './order_exporter.rb'
require_relative './product_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class MissingExporterError < ExportError; end

      class MagentoExporter
        def self.for(type: nil)
          case type
          when 'customer'
            CustomerExporter
          when 'order'
            OrderExporter
          when 'product'
            ProductExporter
          else
            raise MissingExporterError
          end
        end
      end
    end
  end
end
