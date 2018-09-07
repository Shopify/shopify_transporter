# frozen_string_literal: true

require_relative './customer_exporter.rb'
require_relative './order_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class MissingExporterError < ExportError; end

      class MagentoExporter
        def self.for(type, store_id, client)
          case type
          when 'customer'
            CustomerExporter
          when 'order'
            OrderExporter
          else
            raise MissingExporterError
          end.new(store_id, client)
        end
      end
    end
  end
end
